-- Function to create pending business profile on user signup
CREATE OR REPLACE FUNCTION create_pending_business_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create pending profile if user needs business profile
  IF (NEW.raw_user_meta_data->>'needs_business_profile')::boolean = true THEN
    INSERT INTO business_profiles (
      name,
      type,
      contact_email,
      status,
      status_updated_at
    ) VALUES (
      'Pending Business',  -- Placeholder name
      'Pending',          -- Placeholder type
      NEW.email,          -- Use signup email
      'pending_setup',
      now()
    ) RETURNING id INTO NEW.raw_user_meta_data->>'pending_business_id';
    
    -- Update user metadata with pending business ID
    UPDATE auth.users
    SET raw_user_meta_data = NEW.raw_user_meta_data
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to create pending business profile
CREATE TRIGGER on_auth_user_created_pending_business
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_pending_business_profile();

-- Update business profiles RLS to allow viewing pending profiles
DROP POLICY IF EXISTS "Users can view their business profiles" ON business_profiles;

CREATE POLICY "Users can view their business profiles"
  ON business_profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Allow if user has a role for this business
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
    )
    OR
    -- Allow if this is the user's pending business
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );