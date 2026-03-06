-- Create generation type enum
CREATE TYPE generation_type AS ENUM ('hashtag', 'caption');

CREATE TABLE ai_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    photo_id UUID NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    generation_type generation_type NOT NULL,
    model VARCHAR(100) NOT NULL DEFAULT 'gemini-3-flash-preview',
    prompt TEXT,
    result JSONB NOT NULL DEFAULT '{}',
    style VARCHAR(50),
    language VARCHAR(10) NOT NULL DEFAULT 'ja',
    latency_ms INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE ai_generations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own generations"
    ON ai_generations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own generations"
    ON ai_generations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_ai_generations_user_id ON ai_generations(user_id);
CREATE INDEX idx_ai_generations_photo_id ON ai_generations(photo_id);
CREATE INDEX idx_ai_generations_created_at ON ai_generations(created_at DESC);
