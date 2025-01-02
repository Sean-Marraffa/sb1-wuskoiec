-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS before_business_profile_insert ON business_profiles;
DROP FUNCTION IF EXISTS update_pending_business_profile();

-- Create improved function to handle business profile updates
CREATE OR REPLACE FUNCTION update_pending_business_profile()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
  pending_business_id uuid;
  user_id uuid;
BEGIN
  -- Get the user ID from the current session
  user_id := auth.uid();
  
  -- Get pending business ID from user metadata
  SELECT (raw_user_meta_data->>'pending_business_id')::uuid
  INTO pending_business_id
  FROM auth.users
  WHERE id = user_id;

  -- If there's a pending business, update it
  IF pending_business_id IS NOT NULL THEN
    -- Update the pending business with new data
    UPDATE business_profiles
    SET
      name = NEW.name,
      type = NEW.type,
      contact_email = NEW.contact_email,
      street_address_1 = NEW.street_address_1,
      street_address_2 = NEW.street_address_2,
      city = NEW.city,
      state_province = NEW.state_province,
      postal_code = NEW.postal_code,
      country = NEW.country,
      status = 'profile_created',
      status_updated_at = now(),
      updated_at = now()
    WHERE id = pending_business_id;

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

    -- Create user role for the business owner if it doesn't exist
    INSERT INTO user_roles (
      user_id,
      business_id,
      role
    )
    SELECT user_id, pending_business_id, 'Account Owner'
    WHERE NOT EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = user_id
      AND business_id = pending_business_id
    );

    -- Update user metadata
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_build_object(
      'needs_business_profile', false,
      'has_billing', false
    )
    WHERE id = user_id;

    -- Return NULL to prevent the insert since we updated the existing record
    RETURN NULL;
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger to handle business profile updates
CREATE TRIGGER before_business_profile_insert
  BEFORE INSERT ON business_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_pending_business_profile();