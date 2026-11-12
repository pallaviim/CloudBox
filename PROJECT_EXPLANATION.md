# Project explanation

## What it does
CloudBox lets an authenticated user upload files to private Supabase cloud storage, see metadata, search and filter the list, download through short-lived signed URLs, and delete files.

## Architecture
The browser renders React pages. `src/lib/supabase.js` creates the Supabase JavaScript client from Vite environment variables. The client talks over HTTPS to Supabase Auth, PostgreSQL, and Storage. Auth maintains the user's session. PostgreSQL holds file name, owner, size, MIME type, storage path, and timestamp; Storage holds the file bytes. RLS policies in `supabase/setup.sql` enforce ownership independently of the interface.

## Main source files
- `src/App.jsx`: login, registration, protected application shell, dashboard, search/filter, account view, and event handlers.
- `src/lib/supabase.js`: reads the public project URL and anon key and initializes the client.
- `src/lib/files.js`: list, upload, signed download, and delete operations. It creates paths beginning with the user's Auth UUID and rolls back a Storage object when metadata insertion fails.
- `src/style.css`: responsive light dashboard and authentication page styles.
- `supabase/setup.sql`: metadata table, private bucket, and database/Storage ownership policies.

## File upload, download, deletion
Upload sends each selected browser File directly to Storage. After Storage accepts it, the app records its metadata in PostgreSQL. If the database insert fails, it tries to remove the just-uploaded object. Download requests a signed URL valid for 60 seconds. Delete removes the Storage object and then the metadata; if metadata removal fails, the app reports the partial failure.

## Security
The bucket is private. The frontend contains only the public anon/publishable key, which is intended for browser clients; never use a service-role key in Vite. Authenticated table policies compare `owner_id` with `auth.uid()`. Storage policies require the first folder segment to match the user's UUID. Signed download links are temporary.

## Demonstration
Create an account and sign in, upload a small PDF or image, inspect the dashboard metadata, search/filter it, download it, then delete it. Create a second account in a private browser window and confirm it cannot list or download the first account's file. Refresh to verify metadata persistence.
