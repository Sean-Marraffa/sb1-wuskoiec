-- Drop existing function
DROP FUNCTION IF EXISTS set_default_business(uuid);

-- Recreate function with unambiguous parameter name
CREATE OR REPLACE FUNCTION set_default_business(
  target_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Check if user has access to this business
  IF NOT EXISTS (
    SELECT 1 FROM business_memberships
    WHERE user_id = auth.uid()
    AND business_id = target_id
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
  AND business_id = target_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION set_default_business TO authenticated;