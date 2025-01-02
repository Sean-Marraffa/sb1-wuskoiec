-- Drop existing functions first
DROP FUNCTION IF EXISTS get_default_business_profile();
DROP FUNCTION IF EXISTS set_default_business_profile(uuid);

-- Add is_default column to user_roles if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_roles' AND column_name = 'is_default'
  ) THEN
    ALTER TABLE user_roles ADD COLUMN is_default boolean DEFAULT false;
  END IF;
END $$;

-- Create unique constraint to ensure only one default per user
DROP INDEX IF EXISTS idx_user_roles_default;
CREATE UNIQUE INDEX idx_user_roles_default 
ON user_roles(user_id) 
WHERE is_default = true;

-- Function to set default business profile
CREATE FUNCTION set_default_business_profile(
  target_business_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Check if user has access to this business
  IF NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
    AND business_id = target_business_id
  ) THEN
    RAISE EXCEPTION 'User does not have access to this business';
  END IF;

  -- Clear existing default
  UPDATE user_roles
  SET is_default = false
  WHERE user_id = auth.uid()
  AND is_default = true;

  -- Set new default
  UPDATE user_roles
  SET is_default = true
  WHERE user_id = auth.uid()
  AND business_id = target_business_id;
END;
$$;

-- Function to get default business profile with role info
CREATE FUNCTION get_default_business_profile()
RETURNS TABLE (
  business_id uuid,
  business_name text,
  role text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Try to get explicitly set default first
  RETURN QUERY
  SELECT 
    ur.business_id,
    bp.name,
    ur.role
  FROM user_roles ur
  JOIN business_profiles bp ON bp.id = ur.business_id
  WHERE ur.user_id = auth.uid()
  AND ur.is_default = true
  LIMIT 1;

  -- If no default found, get first business and set it as default
  IF NOT FOUND THEN
    RETURN QUERY
    WITH first_business AS (
      SELECT 
        ur.business_id,
        bp.name,
        ur.role
      FROM user_roles ur
      JOIN business_profiles bp ON bp.id = ur.business_id
      WHERE ur.user_id = auth.uid()
      ORDER BY ur.created_at
      LIMIT 1
    )
    SELECT * FROM first_business;

    -- Set as default if found
    UPDATE user_roles
    SET is_default = true
    WHERE user_id = auth.uid()
    AND business_id = (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      ORDER BY created_at 
      LIMIT 1
    );
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION set_default_business_profile TO authenticated;
GRANT EXECUTE ON FUNCTION get_default_business_profile TO authenticated;

-- Create index for efficient role lookups
CREATE INDEX IF NOT EXISTS idx_user_roles_lookup 
ON user_roles(user_id, business_id, role);