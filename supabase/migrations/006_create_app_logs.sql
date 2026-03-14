-- App logs table for persistent logging
CREATE TABLE app_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    level VARCHAR(10) NOT NULL,
    logger_name VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    user_id UUID,
    request_method VARCHAR(10),
    request_path VARCHAR(2048),
    status_code INTEGER,
    duration_ms REAL,
    extra JSONB DEFAULT '{}',
    traceback TEXT
);

-- RLS enabled with no policies = only admin client can read/write
ALTER TABLE app_logs ENABLE ROW LEVEL SECURITY;

-- Indexes for common queries
CREATE INDEX idx_app_logs_timestamp ON app_logs(timestamp DESC);
CREATE INDEX idx_app_logs_level ON app_logs(level);
CREATE INDEX idx_app_logs_logger_name ON app_logs(logger_name);
CREATE INDEX idx_app_logs_user_id ON app_logs(user_id) WHERE user_id IS NOT NULL;
