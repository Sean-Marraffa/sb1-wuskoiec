-- Drop existing functions
DROP FUNCTION IF EXISTS get_default_business();
DROP FUNCTION IF EXISTS set_default_business();

-- Function to set default business
CREATE OR REPLACE FUNCTION set_default_business(
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
SET search_path = public, auth
AS $$
BEGIN
  -- Try to get explicitly set default
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

  -- If no rows returned, get first business
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

    -- Set this as default
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION set_default_business TO authenticated;
GRANT EXECUTE ON FUNCTION get_default_business TO authenticated;