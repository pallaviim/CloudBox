# Cloud-Based File Sharing System

## Abstract
A browser-based private cloud drive for uploading, organizing, downloading, and deleting files. React communicates with Supabase Auth, PostgreSQL, and private object storage over the Supabase JavaScript client.

## Introduction and problem
Files kept only on one device are difficult to reach elsewhere and share securely. This project demonstrates remote object storage with authenticated access and user-specific authorization.

## Objectives
- Authenticate users with Supabase Auth.
- Store real files in a private cloud bucket.
- Keep searchable metadata in PostgreSQL.
- Enforce per-user access through RLS and signed downloads.

## Existing and proposed systems
The conventional approach relies on local folders or manual copies, which limits remote access and central control. The proposed system stores files remotely and applies ownership checks to each metadata and object request.

## Architecture
Browser (React/Vite) → Supabase client over HTTPS → Supabase Auth, PostgreSQL, and Storage. Auth supplies the user's session; PostgreSQL stores file metadata; Storage stores file contents.

## Requirements
Hardware: computer with a modern browser and internet access. Software: Node.js/npm, VS Code (optional), a Supabase account/project, and a modern browser.

## Technology stack
React, Vite, JavaScript, CSS, Supabase Auth, PostgreSQL, and Supabase Storage.

## Folder structure
```text
src/App.jsx              UI, routes-by-state, auth and file actions
src/lib/supabase.js      Supabase browser client configuration
src/lib/files.js         Storage and metadata operations
src/style.css            Responsive interface styles
supabase/setup.sql       Table, private bucket, and RLS policies
.env.example             Required environment variable names
PROJECT_EXPLANATION.md   Beginner guide to the main components
```

## Database design
`public.files` has UUID primary key, Auth owner UUID, display name, unique object path, MIME type, byte size, and creation timestamp. Owner policies allow authenticated users to select, insert, or delete only rows whose owner is their own Auth UUID. Storage policies independently limit objects to the `user-files` bucket and a top-level folder matching that UUID.

## Application workflow
Register/sign in → select files → upload to the user's Storage folder → insert metadata → list/search/filter metadata → request a 60-second signed download URL → delete object and metadata.

## Setup
1. Install Node.js LTS from [nodejs.org](https://nodejs.org/) if `node --version` and `npm --version` do not work.
2. In [Supabase](https://supabase.com/), create an account and a new project. Wait for provisioning to finish.
3. In the project dashboard, open **SQL Editor → New query**, paste all of `supabase/setup.sql`, and run it. The script creates the `user-files` private bucket as well as the table and policies.
4. Open **Project Settings → API** (or **Data API** depending on dashboard version). Copy the Project URL and the publishable/anon key. Never copy the `service_role` secret into this app.
5. Copy `.env.example` to `.env.local` in the project root and replace the two values with your URL and public key. Do not add quotes. `.env.local` is ignored by Git.
6. In Supabase **Authentication → Providers → Email**, keep Email enabled. For a quick classroom demo, under **Authentication → URL Configuration**, set the Site URL to `http://localhost:5173`. If email confirmation is on, confirm your address using the email Supabase sends before signing in.
7. In the project folder terminal, run `npm install`, then `npm run dev`. Open the printed local URL, usually `http://localhost:5173`.
8. To check a production bundle, run `npm run build`; Vite writes the output to `dist/`.

## Configuration and data safety
The browser anon/publishable key is public by design; access is constrained by RLS. The service-role key bypasses policies and must never be placed in frontend code. The bucket must remain private. This project limits individual uploads to 50 MB.

## Testing checklist
- Register, confirm email if required, sign in, and sign out.
- Visit the dashboard while signed out and confirm the sign-in page is shown.
- Upload a PDF and an image; verify file count, size, type, and date.
- Upload more than one file; check feedback for individual failures.
- Search by name and filter by type.
- Download and delete files, then refresh and confirm persistence.
- Sign in as a second user and confirm the first user's files do not appear or download.
- Inspect the bucket settings and confirm `user-files` is private.

## Expected output
After configuration, each authenticated account sees only its own files. The overview shows statistics derived from database records, and downloads use temporary URLs.

## Limitations and future enhancements
Uploads currently run sequentially and show an activity message rather than byte-level progress. There is no resumable upload, sharing link, quota enforcement, or profile editing. Future work could add resumable transfers, configurable quotas, link sharing with expiry, and server-side virus scanning.

## Conclusion
This project demonstrates client-server communication, authenticated cloud services, PostgreSQL metadata, private object storage, and row-level access control in a manageable full-stack application.
