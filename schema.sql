-- Add comment_image_url column to song_comments
ALTER TABLE song_comments 
  ADD COLUMN IF NOT EXISTS comment_image_url TEXT;

-- Update the content constraint to allow either content or comment_image_url
ALTER TABLE song_comments 
  DROP CONSTRAINT IF EXISTS content_not_empty;

ALTER TABLE song_comments
  ADD CONSTRAINT content_or_image_required 
  CHECK (
    (content IS NOT NULL AND length(trim(content)) > 0) OR 
    (comment_image_url IS NOT NULL AND length(trim(comment_image_url)) > 0)
  );

-- Storage policies for comment_images bucket
-- Note: First create the bucket named 'comment_images' in Supabase dashboard

-- Allow authenticated users to upload images
CREATE POLICY "Users can upload comment images"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'comment_images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow anyone to view comment images
CREATE POLICY "Anyone can view comment images"
ON storage.objects FOR SELECT
USING (bucket_id = 'comment_images');

-- Allow users to delete their own comment images
CREATE POLICY "Users can delete own comment images"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'comment_images' AND
  auth.uid()::text = (storage.foldername(name))[1]
); 