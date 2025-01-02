-- Drop existing trigger and function
DROP TRIGGER IF EXISTS before_business_profile_insert ON business_profiles;
DROP FUNCTION IF EXISTS update_pending_business_profile();

-- Create improved function with better conflict handling
CREATE OR REPLACE FUNCTION update_pending_business_profile()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
  pending_business_id uuid;
  current_user_id uuid;
BEGIN
  -- Get the user ID from the current session
  current_user_id := auth.uid();
  
  -- Get pending business ID from user metadata
  SELECT (raw_user_meta_data->>'pending_business_id')::uuid
  INTO pending_business_id
  FROM auth.users
  WHERE id = current_user_id;

  -- If there's a pending business, update it
  IF pending_business_id IS NOT NULL THEN
    -- Set the ID to match the pending business
    NEW.id := pending_business_id;
    NEW.status := 'profile_created';
    NEW.status_updated_at := now();
    NEW.updated_at := now();

    -- Create user role for the business owner if it doesn't exist
    INSERT INTO user_roles (
      user_id,
      business_id,
      role
    )
    SELECT current_user_id, pending_business_id, 'Account Owner'
    WHERE NOT EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = current_user_id
      AND business_id = pending_business_id
    );

    -- Update completion tracking
    UPDATE business_profile_completion
    SET is_complete = true
    WHERE business_id = pending_business_id
    AND field_name IN (
      'name',
      'type',
      'contact_email',
      'street_address_1',
      'city',
      'state_province',
      'postal_code',
      'country'
    );

    -- Update user metadata
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_build_object(
      'needs_business_profile', false,
      'has_billing', false
    )
    WHERE id = current_user_id;
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger to handle business profile updates
CREATE TRIGGER before_business_profile_insert
  BEFORE INSERT ON business_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_pending_business_profile();