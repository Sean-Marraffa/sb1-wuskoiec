-- Create denormalized role table
CREATE TABLE business_role_cache (
  business_id uuid NOT NULL,
  user_id uuid NOT NULL,
  is_owner boolean NOT NULL DEFAULT false,
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (business_id, user_id)
);

-- Enable RLS
ALTER TABLE business_role_cache ENABLE ROW LEVEL SECURITY;

-- Create policy for role cache
CREATE POLICY "role_cache_access" ON business_role_cache
  FOR SELECT TO authenticated
  USING (true);

-- Function to maintain role cache
CREATE OR REPLACE FUNCTION maintain_role_cache()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    INSERT INTO business_role_cache (business_id, user_id, is_owner)
    VALUES (NEW.business_id, NEW.user_id, NEW.role = 'Account Owner')
    ON CONFLICT (business_id, user_id) 
    DO UPDATE SET 
      is_owner = NEW.role = 'Account Owner',
      updated_at = now();
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM business_role_cache 
    WHERE business_id = OLD.business_id AND user_id = OLD.user_id;
  END IF;
  RETURN NULL;
END;
$$;

-- Create trigger for role cache
CREATE TRIGGER maintain_role_cache_trigger
AFTER INSERT OR UPDATE OR DELETE ON business_memberships
FOR EACH ROW EXECUTE FUNCTION maintain_role_cache();

-- Populate initial cache
INSERT INTO business_role_cache (business_id, user_id, is_owner)
SELECT DISTINCT 
  business_id,
  user_id,
  role = 'Account Owner'
FROM business_memberships
ON CONFLICT DO NOTHING;

-- Drop existing policies
DROP POLICY IF EXISTS "allow_super_admin" ON business_memberships;
DROP POLICY IF EXISTS "allow_select_own" ON business_memberships;
DROP POLICY IF EXISTS "allow_select_as_owner" ON business_memberships;
DROP POLICY IF EXISTS "allow_insert_as_owner" ON business_memberships;
DROP POLICY IF EXISTS "allow_update_as_owner" ON business_memberships;
DROP POLICY IF EXISTS "allow_delete_as_owner" ON business_memberships;

-- Create new non-recursive policies using role cache
CREATE POLICY "membership_select"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM business_role_cache
      WHERE user_id = auth.uid()
      AND business_id = business_memberships.business_id
      AND is_owner = true
      LIMIT 1
    )
    OR
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
  );

CREATE POLICY "membership_write"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    (
      role = 'Team Member'
      AND
      EXISTS (
        SELECT 1 FROM business_role_cache
        WHERE user_id = auth.uid()
        AND business_id = business_memberships.business_id
        AND is_owner = true
        LIMIT 1
      )
    )
    OR
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
  )
  WITH CHECK (
    (
      role = 'Team Member'
      AND
      EXISTS (
        SELECT 1 FROM business_role_cache
        WHERE user_id = auth.uid()
        AND business_id = business_memberships.business_id
        AND is_owner = true
        LIMIT 1
      )
    )
    OR
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
  );

-- Create efficient indexes
DROP INDEX IF EXISTS idx_memberships_lookup_v5;
DROP INDEX IF EXISTS idx_memberships_owner_v5;

CREATE INDEX idx_memberships_lookup_v6 
ON business_memberships(user_id, business_id, role);

CREATE INDEX idx_role_cache_lookup
ON business_role_cache(user_id, business_id, is_owner);