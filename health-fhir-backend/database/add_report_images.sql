-- Add image_urls column to reports table
ALTER TABLE reports 
ADD COLUMN IF NOT EXISTS image_urls TEXT[];

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_reports_image_urls ON reports USING GIN(image_urls);

