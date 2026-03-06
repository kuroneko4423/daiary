-- Seed data for development environment
-- Note: auth.users must be created via Supabase Auth API in dev.
-- This seed assumes two test users already exist in auth.users.
-- When using `supabase start`, you can create test users via the dashboard or CLI.

-- Test user UUIDs (deterministic for development)
-- User 1: test@example.com  -> 11111111-1111-1111-1111-111111111111
-- User 2: test2@example.com -> 22222222-2222-2222-2222-222222222222

-- Insert test users into public.users (only if auth.users exist)
DO $$
BEGIN
    -- Only seed if users table is empty
    IF NOT EXISTS (SELECT 1 FROM public.users LIMIT 1) THEN

        -- Insert test user 1 (free plan)
        INSERT INTO public.users (id, email, username, plan, daily_ai_count, storage_used_bytes)
        VALUES (
            '11111111-1111-1111-1111-111111111111',
            'test@example.com',
            'testuser',
            'free',
            3,
            5242880 -- 5MB
        ) ON CONFLICT (id) DO NOTHING;

        -- Insert test user 2 (premium plan)
        INSERT INTO public.users (id, email, username, plan, plan_expires_at, daily_ai_count, storage_used_bytes)
        VALUES (
            '22222222-2222-2222-2222-222222222222',
            'test2@example.com',
            'premiumuser',
            'premium',
            NOW() + INTERVAL '30 days',
            15,
            52428800 -- 50MB
        ) ON CONFLICT (id) DO NOTHING;

        -- Insert sample photos for user 1
        INSERT INTO public.photos (id, user_id, storage_path, thumbnail_path, original_filename, file_size, width, height, exif_data, ai_tags, is_favorite)
        VALUES
        (
            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            '11111111-1111-1111-1111-111111111111',
            '11111111-1111-1111-1111-111111111111/photos/sunset.jpg',
            '11111111-1111-1111-1111-111111111111/thumbnails/sunset_thumb.jpg',
            'sunset.jpg',
            2097152, -- 2MB
            4032,
            3024,
            '{"Make": "Apple", "Model": "iPhone 15 Pro", "DateTimeOriginal": "2025:12:01 17:30:00", "GPSLatitude": 35.6762, "GPSLongitude": 139.6503}',
            '["sunset", "sky", "orange", "landscape", "tokyo"]',
            TRUE
        ),
        (
            'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            '11111111-1111-1111-1111-111111111111',
            '11111111-1111-1111-1111-111111111111/photos/cafe.jpg',
            '11111111-1111-1111-1111-111111111111/thumbnails/cafe_thumb.jpg',
            'cafe.jpg',
            1572864, -- 1.5MB
            3024,
            4032,
            '{"Make": "Apple", "Model": "iPhone 15 Pro", "DateTimeOriginal": "2025:12:05 14:00:00"}',
            '["cafe", "coffee", "interior", "warm", "cozy"]',
            FALSE
        ),
        (
            'cccccccc-cccc-cccc-cccc-cccccccccccc',
            '11111111-1111-1111-1111-111111111111',
            '11111111-1111-1111-1111-111111111111/photos/sakura.jpg',
            '11111111-1111-1111-1111-111111111111/thumbnails/sakura_thumb.jpg',
            'sakura.jpg',
            3145728, -- 3MB
            4032,
            3024,
            '{"Make": "Sony", "Model": "ILCE-7M4", "DateTimeOriginal": "2025:03:28 10:15:00", "FocalLength": 85}',
            '["sakura", "spring", "flowers", "pink", "japan"]',
            TRUE
        );

        -- Insert sample photos for user 2
        INSERT INTO public.photos (id, user_id, storage_path, thumbnail_path, original_filename, file_size, width, height, ai_tags)
        VALUES
        (
            'dddddddd-dddd-dddd-dddd-dddddddddddd',
            '22222222-2222-2222-2222-222222222222',
            '22222222-2222-2222-2222-222222222222/photos/portrait.jpg',
            '22222222-2222-2222-2222-222222222222/thumbnails/portrait_thumb.jpg',
            'portrait.jpg',
            2621440, -- 2.5MB
            3024,
            4032,
            '["portrait", "person", "bokeh", "natural light"]'
        ),
        (
            'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
            '22222222-2222-2222-2222-222222222222',
            '22222222-2222-2222-2222-222222222222/photos/cityscape.jpg',
            '22222222-2222-2222-2222-222222222222/thumbnails/cityscape_thumb.jpg',
            'cityscape.jpg',
            4194304, -- 4MB
            6000,
            4000,
            '["cityscape", "night", "lights", "urban", "tokyo"]'
        );

        -- Insert sample albums for user 1
        INSERT INTO public.albums (id, user_id, name, cover_photo_id, is_public, share_token)
        VALUES
        (
            'ffffffff-ffff-ffff-ffff-ffffffffffff',
            '11111111-1111-1111-1111-111111111111',
            'Tokyo Favorites',
            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            TRUE,
            'share_abc123def456'
        ),
        (
            '99999999-9999-9999-9999-999999999999',
            '11111111-1111-1111-1111-111111111111',
            'Spring 2025',
            'cccccccc-cccc-cccc-cccc-cccccccccccc',
            FALSE,
            NULL
        );

        -- Add photos to albums
        INSERT INTO public.album_photos (album_id, photo_id, sort_order)
        VALUES
        ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 0),
        ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1),
        ('99999999-9999-9999-9999-999999999999', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 0);

        -- Insert sample AI generations
        INSERT INTO public.ai_generations (user_id, photo_id, generation_type, model, prompt, result, style, language, latency_ms)
        VALUES
        (
            '11111111-1111-1111-1111-111111111111',
            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            'hashtag',
            'gemini-3-flash-preview',
            'Generate Instagram hashtags for this sunset photo',
            '{"hashtags": ["#sunset", "#tokyosunset", "#goldenhour", "#skyporn", "#landscapephotography", "#japan", "#tokyophotography", "#eveningsky", "#sunsetlovers", "#photooftheday"]}',
            'instagram',
            'en',
            1250
        ),
        (
            '11111111-1111-1111-1111-111111111111',
            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            'caption',
            'gemini-3-flash-preview',
            'Write a poetic Japanese caption for this sunset photo',
            '{"caption": "東京の空が燃えるように染まる夕暮れ。都会の喧騒を忘れさせてくれる、一日の終わりの贈り物。"}',
            'poetic',
            'ja',
            980
        ),
        (
            '22222222-2222-2222-2222-222222222222',
            'dddddddd-dddd-dddd-dddd-dddddddddddd',
            'hashtag',
            'gemini-3-flash-preview',
            'Generate hashtags for this portrait photo',
            '{"hashtags": ["#portrait", "#portraitphotography", "#bokeh", "#naturallight", "#photography", "#photooftheday", "#portraitmode", "#headshot"]}',
            'instagram',
            'en',
            1100
        );

        RAISE NOTICE 'Seed data inserted successfully';
    ELSE
        RAISE NOTICE 'Users table is not empty, skipping seed data';
    END IF;
END $$;
