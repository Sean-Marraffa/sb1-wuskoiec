-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created_pending_business ON auth.users;
DROP FUNCTION IF EXISTS create_pending_business_profile();

-- Create improved function with better error handling
CREATE OR REPLACE FUNCTION create_pending_business_profile()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
  business_id uuid;
BEGIN
  -- Only create pending profile if user needs business profile
  IF (NEW.raw_user_meta_data->>'needs_business_profile')::boolean = true THEN
    -- Create pending business profile
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
    ) RETURNING id INTO business_id;

    -- Update user metadata with pending business ID
    NEW.raw_user_meta_data = jsonb_set(
      COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
      '{pending_business_id}',
      to_jsonb(business_id::text)
    );
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail the signup
  RAISE WARNING 'Error creating pending business profile: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- Create trigger for new user signups
CREATE TRIGGER on_auth_user_created_pending_business
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_pending_business_profile();