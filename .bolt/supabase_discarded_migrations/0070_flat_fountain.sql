-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS before_business_profile_insert ON business_profiles;
DROP TRIGGER IF EXISTS on_auth_user_created_pending_business ON auth.users;
DROP FUNCTION IF EXISTS update_pending_business_profile();
DROP FUNCTION IF EXISTS create_pending_business_profile();

-- Create function to handle initial business profile creation on signup
CREATE OR REPLACE FUNCTION create_pending_business_profile()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
  business_id uuid;
  updated_metadata jsonb;
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
      'Pending Setup',
      'Pending',
      NEW.email,
      'pending_setup',
      now()
    ) RETURNING id INTO business_id;

    -- Combine all metadata updates into a single operation
    updated_metadata := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);
    updated_metadata := jsonb_set(updated_metadata, '{pending_business_id}', to_jsonb(business_id::text));
    NEW.raw_user_meta_data := updated_metadata;

    -- Initialize completion tracking
    INSERT INTO business_profile_completion (
      business_id,
      field_name,
      is_complete
    )
    SELECT 
      business_id,
      field_name,
      false
    FROM unnest(ARRAY[
      'name',
      'type',
      'contact_email',
      'street_address_1',
      'city',
      'state_province',
      'postal_code',
      'country'
    ]) AS field_name;
  END IF;

  RETURN NEW;
END;
$$;

-- Create function to handle business profile updates
CREATE OR REPLACE FUNCTION update_pending_business_profile()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
  pending_business_id uuid;
  user_id uuid;
  updated_metadata jsonb;
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
    WHERE business_id = pending_business_id;

    -- Create user role for the business owner
    INSERT INTO user_roles (
      user_id,
      business_id,
      role
    ) VALUES (
      user_id,
      pending_business_id,
      'Account Owner'
    );

    -- Update user metadata in a single operation
    SELECT raw_user_meta_data - 'pending_business_id'
    INTO updated_metadata
    FROM auth.users
    WHERE id = user_id;

    updated_metadata := jsonb_set(updated_metadata, '{needs_business_profile}', 'false'::jsonb);

    UPDATE auth.users
    SET raw_user_meta_data = updated_metadata
    WHERE id = user_id;

    -- Return NULL to prevent the INSERT
    RETURN NULL;
  END IF;

  RETURN NEW;
END;
$$;

-- Create triggers
CREATE TRIGGER on_auth_user_created_pending_business
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_pending_business_profile();

CREATE TRIGGER before_business_profile_insert
  BEFORE INSERT ON business_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_pending_business_profile();