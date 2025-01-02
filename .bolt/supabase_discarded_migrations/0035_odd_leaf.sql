-- Drop existing policies
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;

-- Create new policies with correct path handling
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = SPLIT_PART(REPLACE(name, 'avatars/', ''), '.', 1)
  );

CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = SPLIT_PART(REPLACE(name, 'avatars/', ''), '.', 1)
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = SPLIT_PART(REPLACE(name, 'avatars/', ''), '.', 1)
  );

CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = SPLIT_PART(REPLACE(name, 'avatars/', ''), '.', 1)
  );