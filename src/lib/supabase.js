import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY
export const configured = Boolean(url && anonKey)
// This publishable/anon key is designed for browser use. RLS policies protect data;
// never put a service-role key in a frontend environment variable.
export const supabase = configured ? createClient(url, anonKey) : null
