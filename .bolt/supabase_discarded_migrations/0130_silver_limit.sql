-- Create new user_profiles table to store extended user information
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  email text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create business_memberships table to replace user_roles
CREATE TABLE business_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  business_id uuid REFERENCES business_profiles(id) ON DELETE CASCADE NOT NULL,
  role text NOT NULL CHECK (role IN ('Account Owner', 'Team Member')),
  is_default boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, business_id)
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_memberships ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX idx_business_memberships_user ON business_memberships(user_id);
CREATE INDEX idx_business_memberships_business ON business_memberships(business_id);
CREATE INDEX idx_business_memberships_role ON business_memberships(user_id, business_id, role);
CREATE UNIQUE INDEX idx_business_memberships_default ON business_memberships(user_id) WHERE is_default = true;

-- Create policies for user_profiles
CREATE POLICY "users_can_view_own_profile"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "users_can_update_own_profile"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Create policies for business_memberships
CREATE POLICY "users_can_view_own_memberships"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    business_id IN (
      SELECT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "owners_can_manage_memberships"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM business_memberships owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_memberships.business_id
      AND owner.role = 'Account Owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM business_memberships owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_memberships.business_id
      AND owner.role = 'Account Owner'
    )
  );

-- Function to set default business
CREATE OR REPLACE FUNCTION set_default_business(
  business_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user has access to this business
  IF NOT EXISTS (
    SELECT 1 FROM business_memberships
    WHERE user_id = auth.uid()
    AND business_id = set_default_business.business_id
  ) THEN
    RAISE EXCEPTION 'User does not have access to this business';
  END IF;

  -- Clear existing default
  UPDATE business_memberships
  SET is_default = false
  WHERE user_id = auth.uid()
  AND is_default = true;

  -- Set new default
  UPDATE business_memberships
  SET is_default = true
  WHERE user_id = auth.uid()
  AND business_id = set_default_business.business_id;
END;
$$;

-- Function to get default business
CREATE OR REPLACE FUNCTION get_default_business()
RETURNS TABLE (
  business_id uuid,
  business_name text,
  role text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    bm.business_id,
    bp.name as business_name,
    bm.role
  FROM business_memberships bm
  JOIN business_profiles bp ON bp.id = bm.business_id
  WHERE bm.user_id = auth.uid()
  AND bm.is_default = true
  LIMIT 1;

  -- If no default set, get first membership
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT 
      bm.business_id,
      bp.name as business_name,
      bm.role
    FROM business_memberships bm
    JOIN business_profiles bp ON bp.id = bm.business_id
    WHERE bm.user_id = auth.uid()
    ORDER BY bm.created_at
    LIMIT 1;

    -- Set as default if found
    UPDATE business_memberships
    SET is_default = true
    WHERE id = (
      SELECT id
      FROM business_memberships
      WHERE user_id = auth.uid()
      ORDER BY created_at
      LIMIT 1
    );
  END IF;
END;
$$;

-- Migrate existing data
INSERT INTO user_profiles (id, full_name, email)
SELECT 
  id,
  COALESCE(raw_user_meta_data->>'full_name', email) as full_name,
  email
FROM auth.users
ON CONFLICT (id) DO NOTHING;

INSERT INTO business_memberships (user_id, business_id, role, is_default)
SELECT 
  user_id,
  business_id,
  role,
  is_default
FROM user_roles
ON CONFLICT (user_id, business_id) DO NOTHING;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION set_default_business TO authenticated;
GRANT EXECUTE ON FUNCTION get_default_business TO authenticated;