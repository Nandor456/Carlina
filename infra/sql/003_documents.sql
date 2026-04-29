-- ─────────────────────────────────────────
-- DOCUMENTS
-- Depends on: 002_vehicles.sql
-- ─────────────────────────────────────────

-- Enums
DO $$ BEGIN
    CREATE TYPE document_type   AS ENUM ('RCA', 'ITP', 'ROVINIETA');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE document_status AS ENUM ('ACTIVE', 'EXPIRING_SOON', 'EXPIRED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS documents (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id      UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    document_type   document_type   NOT NULL,
    issue_date      DATE NOT NULL,
    expiration_date DATE NOT NULL,
    -- Status is derived and refreshed daily by the cron job
    status          document_status NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Only one active record per document type per vehicle
    CONSTRAINT uq_documents_vehicle_type UNIQUE (vehicle_id, document_type)
);

CREATE INDEX IF NOT EXISTS idx_documents_vehicle_id      ON documents (vehicle_id);
CREATE INDEX IF NOT EXISTS idx_documents_expiration_date ON documents (expiration_date);
CREATE INDEX IF NOT EXISTS idx_documents_status          ON documents (status);

CREATE TRIGGER trg_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ─────────────────────────────────────────
-- Express-session store (connect-pg-simple)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS session (
    sid    VARCHAR NOT NULL COLLATE "default" PRIMARY KEY,
    sess   JSON    NOT NULL,
    expire TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_session_expire ON session (expire);
