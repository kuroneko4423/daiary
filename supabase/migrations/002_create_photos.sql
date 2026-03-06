CREATE TABLE photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    thumbnail_path TEXT,
    original_filename VARCHAR(500),
    file_size BIGINT,
    width INTEGER,
    height INTEGER,
    exif_data JSONB DEFAULT '{}',
    ai_tags JSONB DEFAULT '[]',
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own photos"
    ON photos FOR SELECT
    USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "Users can view own deleted photos"
    ON photos FOR SELECT
    USING (auth.uid() = user_id AND deleted_at IS NOT NULL);

CREATE POLICY "Users can insert own photos"
    ON photos FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own photos"
    ON photos FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own photos"
    ON photos FOR DELETE
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_photos_user_id ON photos(user_id);
CREATE INDEX idx_photos_created_at ON photos(created_at DESC);
CREATE INDEX idx_photos_is_favorite ON photos(user_id, is_favorite) WHERE is_favorite = TRUE;
CREATE INDEX idx_photos_ai_tags ON photos USING GIN(ai_tags);
CREATE INDEX idx_photos_deleted_at ON photos(deleted_at) WHERE deleted_at IS NOT NULL;
