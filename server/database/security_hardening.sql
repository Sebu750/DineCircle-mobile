-- Phase 4: Database security hardening
-- Run as superuser to create restricted API user and audit table.

-- 1. Audit log table
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  action TEXT NOT NULL,
  resource TEXT NOT NULL,
  resource_id UUID,
  changes JSONB DEFAULT '{}',
  status_code INTEGER,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_resource ON audit_log (resource);

-- 2. Create a dedicated API user with minimal permissions
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'dinecircle_api') THEN
    CREATE USER dinecircle_api WITH PASSWORD 'dc_api_change_me_in_production';
  END IF;
END
$$;

-- Grant only the minimum required privileges
GRANT CONNECT ON DATABASE dinecircle TO dinecircle_api;
GRANT USAGE ON SCHEMA public TO dinecircle_api;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dinecircle_api;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dinecircle_api;

-- Revoke default public schema access
REVOKE ALL ON DATABASE dinecircle FROM PUBLIC;

-- 3. Row-Level Security policies for multi-tenant isolation
-- Restaurants: partner admins can only modify their own restaurants
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;

CREATE POLICY partner_own_restaurants ON restaurants
  FOR ALL
  USING (owner_id = current_setting('app.current_user_id', true)::UUID)
  WITH CHECK (owner_id = current_setting('app.current_user_id', true)::UUID);

-- Partner admins can still see all restaurants for browsing
CREATE POLICY any_user_view_restaurants ON restaurants
  FOR SELECT
  USING (true);

-- Bookings: users can only see their own bookings
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_own_bookings ON bookings
  FOR ALL
  USING (
    user_id = current_setting('app.current_user_id', true)::UUID
    OR event_id IN (
      SELECT de.id FROM dinner_events de
      JOIN restaurants r ON r.id = de.restaurant_id
      WHERE r.owner_id = current_setting('app.current_user_id', true)::UUID
    )
  );

-- Auth tokens: users can only see their own tokens
ALTER TABLE auth_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_own_tokens ON auth_tokens
  FOR ALL
  USING (user_id = current_setting('app.current_user_id', true)::UUID);
