/*
  # Create auth user trigger

  Creates the trigger and function to handle new user creation and business setup
*/

-- Create the function first
CREATE OR REPLACE FUNCTION create_pending_business()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
  business_id uuid;
BEGIN
  IF (NEW.raw_user_meta_data->>'needs_business_profile')::boolean = true THEN
    -- Create pending business profile
    INSERT INTO business_profiles (
      name,
      type,
      contact_email,
      status,
      status_updated_at
    ) VALUES (
      'Pending Setup',
      'Pending',
      NEW.email,
      'pending_setup',
      now()
    ) RETURNING id INTO business_id;

    -- Create business user association with Account Owner role
    INSERT INTO business_users (
      user_id,
      business_id,
      role,
      is_default
    ) VALUES (
      NEW.id,
      business_id,
      'Account Owner',
      true
    );

    -- Update user metadata with pending business ID
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_set(
      COALESCE(raw_user_meta_data, '{}'::jsonb),
      '{pending_business_id}',
      to_jsonb(business_id::text)
    )
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER on_auth_user_created_pending_business
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_pending_business();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_pending_business TO authenticated;
GRANT EXECUTE ON FUNCTION create_pending_business TO anon;

-- Add helpful comment
COMMENT ON FUNCTION create_pending_business IS 'Creates pending business profile and associates the user as Account Owner when a new user signs up with needs_business_profile flag.';