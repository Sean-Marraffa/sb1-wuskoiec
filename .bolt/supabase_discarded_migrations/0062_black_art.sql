-- Create table for tracking profile completion
CREATE TABLE business_profile_completion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES business_profiles(id) ON DELETE CASCADE,
  field_name text NOT NULL,
  is_complete boolean DEFAULT false,
  updated_at timestamptz DEFAULT now()
);

-- Add completion percentage to business_profiles
ALTER TABLE business_profiles 
ADD COLUMN completion_percentage integer DEFAULT 0;

-- Enable RLS
ALTER TABLE business_profile_completion ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Super admins can do everything"
  ON business_profile_completion
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "Business owners can view their completion status"
  ON business_profile_completion
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = business_profile_completion.business_id
      AND user_roles.user_id = auth.uid()
    )
  );

-- Function to initialize profile completion tracking
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

-- Create trigger for new business profiles
CREATE TRIGGER on_business_profile_created
  AFTER INSERT ON business_profiles
  FOR EACH ROW
  EXECUTE FUNCTION initialize_profile_completion();

-- Function to update completion percentage
CREATE OR REPLACE FUNCTION update_completion_percentage()
RETURNS TRIGGER AS $$
DECLARE
  total_fields integer;
  completed_fields integer;
  completion integer;
BEGIN
  -- Get counts
  SELECT COUNT(*), COUNT(*) FILTER (WHERE is_complete)
  INTO total_fields, completed_fields
  FROM business_profile_completion
  WHERE business_id = NEW.business_id;

  -- Calculate percentage
  completion := CASE 
    WHEN total_fields > 0 
    THEN (completed_fields * 100 / total_fields)
    ELSE 0
  END;

  -- Update business profile
  UPDATE business_profiles
  SET completion_percentage = completion
  WHERE id = NEW.business_id;

  -- Update status if needed
  IF completion = 100 AND (
    SELECT status FROM business_profiles WHERE id = NEW.business_id
  ) = 'pending_setup' THEN
    UPDATE business_profiles
    SET 
      status = 'profile_created',
      status_updated_at = now()
    WHERE id = NEW.business_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for completion updates
CREATE TRIGGER on_completion_updated
  AFTER INSERT OR UPDATE ON business_profile_completion
  FOR EACH ROW
  EXECUTE FUNCTION update_completion_percentage();