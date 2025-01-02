-- Add is_default column to user_roles
ALTER TABLE user_roles
ADD COLUMN is_default boolean DEFAULT false;

-- Create unique constraint to ensure only one default per user
CREATE UNIQUE INDEX idx_user_roles_default 
ON user_roles(user_id) 
WHERE is_default = true;

-- Function to set default business profile
CREATE OR REPLACE FUNCTION set_default_business_profile(
  business_id uuid
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
    AND business_id = set_default_business_profile.business_id
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
  AND business_id = set_default_business_profile.business_id;
END;
$$;

-- Function to get default business profile
CREATE OR REPLACE FUNCTION get_default_business_profile()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  default_business_id uuid;
BEGIN
  -- Try to get explicitly set default
  SELECT business_id INTO default_business_id
  FROM user_roles
  WHERE user_id = auth.uid()
  AND is_default = true
  LIMIT 1;

  -- If no default set, use first business
  IF default_business_id IS NULL THEN
    SELECT business_id INTO default_business_id
    FROM user_roles
    WHERE user_id = auth.uid()
    ORDER BY business_id
    LIMIT 1;

    -- Set this as default if found
    IF default_business_id IS NOT NULL THEN
      PERFORM set_default_business_profile(default_business_id);
    END IF;
  END IF;

  RETURN default_business_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION set_default_business_profile TO authenticated;
GRANT EXECUTE ON FUNCTION get_default_business_profile TO authenticated;