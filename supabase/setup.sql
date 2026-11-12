-- CloudBox database and storage setup.
-- Safe to run more than once: this does not drop the table, bucket, or user data.
-- If the earlier CloudBox schema exists, its metadata columns are renamed in place.

create table if not exists public.files (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  file_name text not null check (length(file_name) between 1 and 255),
  storage_path text not null unique,
  file_type text not null default 'application/octet-stream',
  file_size bigint not null check (file_size >= 0),
  uploaded_at timestamptz not null default now()
);

-- Upgrade the previous CloudBox column names in place, preserving every row.
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='owner_id')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='user_id') then
    alter table public.files rename column owner_id to user_id;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='name')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='file_name') then
    alter table public.files rename column name to file_name;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='mime_type')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='file_type') then
    alter table public.files rename column mime_type to file_type;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='size')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='file_size') then
    alter table public.files rename column size to file_size;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='created_at')
     and not exists (select 1 from information_schema.columns where table_schema='public' and table_name='files' and column_name='uploaded_at') then
    alter table public.files rename column created_at to uploaded_at;
  end if;
end $$;

-- Keep the object folder bound to the authenticated account ID.
alter table public.files drop constraint if exists files_path_owner;
alter table public.files add constraint files_path_owner
  check (split_part(storage_path, '/', 1) = user_id::text);

create index if not exists files_user_uploaded_idx on public.files(user_id, uploaded_at desc);
alter table public.files enable row level security;
grant select, insert, update, delete on public.files to authenticated;

drop policy if exists "Users can read their own file records" on public.files;
create policy "Users can read their own file records" on public.files
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Users can add their own file records" on public.files;
create policy "Users can add their own file records" on public.files
  for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Users can update their own file records" on public.files;
create policy "Users can update their own file records" on public.files
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists "Users can delete their own file records" on public.files;
create policy "Users can delete their own file records" on public.files
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Private bucket. The conflict clause updates bucket settings but never its contents.
insert into storage.buckets (id, name, public, file_size_limit)
values ('user-files', 'user-files', false, 52428800)
on conflict (id) do update set public = false, file_size_limit = 52428800;

drop policy if exists "Users can upload into their own folder" on storage.objects;
create policy "Users can upload into their own folder" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'user-files' and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Users can read objects in their own folder" on storage.objects;
create policy "Users can read objects in their own folder" on storage.objects
  for select to authenticated using (
    bucket_id = 'user-files' and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Users can delete objects in their own folder" on storage.objects;
create policy "Users can delete objects in their own folder" on storage.objects
  for delete to authenticated using (
    bucket_id = 'user-files' and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Make the newly-created/updated public table visible to Supabase's PostgREST API.
notify pgrst, 'reload schema';
