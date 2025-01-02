-- Function to update pending business profile
CREATE OR REPLACE FUNCTION update_pending_business_profile()
RETURNS TRIGGER AS $$
DECLARE
  pending_business_id uuid;
  user_id uuid;
BEGIN
  -- Get the user ID from the current session
  user_id := auth.uid();
  
  -- Get pending business ID from user metadata
  SELECT NULLIF((raw_user_meta_data->>'pending_business_id'), '')::uuid
  INTO pending_business_id
  FROM auth.users
  WHERE id = user_id;

  -- If there's a pending business, update it instead of creating new
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

    -- Set the ID to the pending business ID
    NEW.id := pending_business_id;
    
    -- Clear the pending business ID from user metadata
    UPDATE auth.users
    SET raw_user_meta_data = raw_user_meta_data - 'pending_business_id'
    WHERE id = user_id;

    RETURN NULL; -- Prevent the insert
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to handle business profile updates
CREATE TRIGGER before_business_profile_insert
  BEFORE INSERT ON business_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_pending_business_profile();

-- Update completion tracking for pending profiles
CREATE OR REPLACE FUNCTION initialize_profile_completion()
RETURNS TRIGGER AS $$
DECLARE
  required_fields text[] := ARRAY[
    'name',
    'type',
    'contact_email',
    'street_address_1',
    'city',
    'state_province',
    'postal_code',
    'country'
  ];
  field text;
BEGIN
  -- Create completion records for each required field
  FOREACH field IN ARRAY required_fields
  LOOP
    INSERT INTO business_profile_completion (
      business_id,
      field_name,
      is_complete
    ) VALUES (
      NEW.id,
      field,
      CASE 
        WHEN NEW.status = 'pending_setup' THEN false
        ELSE true
      END
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;