CREATE TABLE albums (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    cover_photo_id UUID REFERENCES photos(id) ON DELETE SET NULL,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    share_token VARCHAR(64) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_albums_updated_at
    BEFORE UPDATE ON albums
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Junction table
CREATE TABLE album_photos (
    album_id UUID NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    photo_id UUID NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (album_id, photo_id)
);

-- RLS for albums
ALTER TABLE albums ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own albums"
    ON albums FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view public albums by share token"
    ON albums FOR SELECT
    USING (is_public = TRUE AND share_token IS NOT NULL);

CREATE POLICY "Users can insert own albums"
    ON albums FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own albums"
    ON albums FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own albums"
    ON albums FOR DELETE
    USING (auth.uid() = user_id);

-- RLS for album_photos
ALTER TABLE album_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own album photos"
    ON album_photos FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM albums
            WHERE albums.id = album_photos.album_id
            AND albums.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view public album photos"
    ON album_photos FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM albums
            WHERE albums.id = album_photos.album_id
            AND albums.is_public = TRUE
        )
    );

CREATE POLICY "Users can manage own album photos"
    ON album_photos FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM albums
            WHERE albums.id = album_photos.album_id
            AND albums.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own album photos"
    ON album_photos FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM albums
            WHERE albums.id = album_photos.album_id
            AND albums.user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_albums_user_id ON albums(user_id);
CREATE INDEX idx_albums_share_token ON albums(share_token) WHERE share_token IS NOT NULL;
CREATE INDEX idx_album_photos_album_id ON album_photos(album_id);
CREATE INDEX idx_album_photos_photo_id ON album_photos(photo_id);
