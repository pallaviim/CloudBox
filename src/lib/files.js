import { supabase } from './supabase'

const BUCKET = 'user-files'
const MAX_SIZE = 50 * 1024 * 1024

export async function listFiles() {
  // Select from public explicitly; aliases preserve the property names used by the UI.
  const { data, error } = await supabase.schema('public').from('files')
    .select('id,owner_id:user_id,name:file_name,storage_path,mime_type:file_type,size:file_size,created_at:uploaded_at')
    .order('uploaded_at', { ascending: false })
  if (error) throw error
  return data || []
}

export async function uploadFiles(files, userId) {
  const results = []
  for (const file of files) {
    try {
      if (file.size > MAX_SIZE) throw new Error('File is larger than the 50 MB limit.')
      // Store each object below the authenticated user's UUID so Storage RLS can enforce ownership.
      const path = `${userId}/${crypto.randomUUID()}-${file.name.replace(/[\\/]/g, '_')}`
      const { error: storageError } = await supabase.storage.from(BUCKET).upload(path, file, { contentType: file.type || 'application/octet-stream', upsert: false })
      if (storageError) throw storageError
      const { error: dbError } = await supabase.schema('public').from('files').insert({ user_id: userId, file_name: file.name, storage_path: path, file_type: file.type || 'application/octet-stream', file_size: file.size })
      if (dbError) {
        // Roll back the object if metadata insertion fails, to avoid leaving an orphan.
        const { error: cleanupError } = await supabase.storage.from(BUCKET).remove([path])
        if (cleanupError) throw new Error(`Metadata save failed (${dbError.message}); cleanup also failed (${cleanupError.message}).`)
        throw dbError
      }
      results.push({ name: file.name })
    } catch (error) { results.push({ name: file.name, error: error.message }) }
  }
  return results
}

export async function downloadFile(file) {
  const { data, error } = await supabase.storage.from(BUCKET).createSignedUrl(file.storage_path, 60, { download: file.name })
  if (error) throw error
  return data.signedUrl
}

export async function deleteFile(file) {
  // Delete metadata only after Storage confirms removal; a failed metadata delete is reported for repair.
  const { error: storageError } = await supabase.storage.from(BUCKET).remove([file.storage_path])
  if (storageError) throw storageError
  const { error: dbError } = await supabase.schema('public').from('files').delete().eq('id', file.id)
  if (dbError) throw new Error(`Storage object was removed, but its database record could not be deleted: ${dbError.message}`)
}
