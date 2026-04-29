-- ─────────────────────────────────────────
-- VEHICLES
-- Depends on: 001_users.sql
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vehicles (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    license_plate VARCHAR(20)  NOT NULL,           -- e.g. "CJ 01 ABC"
    make          VARCHAR(100) NOT NULL,            -- e.g. "Dacia"
    model         VARCHAR(100) NOT NULL,            -- e.g. "Logan"
    year          SMALLINT,
    vin           VARCHAR(17),                      -- 17-char ISO 3779 VIN, optional
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- A user cannot add the same plate twice
    CONSTRAINT uq_vehicles_user_plate UNIQUE (user_id, license_plate)
);

CREATE INDEX IF NOT EXISTS idx_vehicles_user_id ON vehicles (user_id);

CREATE TRIGGER trg_vehicles_updated_at
    BEFORE UPDATE ON vehicles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
