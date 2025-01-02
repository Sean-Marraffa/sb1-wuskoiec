-- Create enum for business status
CREATE TYPE business_status AS ENUM (
  'pending_setup', -- Owner signed up but hasn't created profile
  'profile_created', -- Business profile created but not fully onboarded
  'active', -- Fully onboarded and operating
  'churned', -- Canceled after being active
  'withdrawn' -- Canceled during onboarding
);

-- Add status tracking table
CREATE TABLE business_status_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES business_profiles(id) ON DELETE CASCADE,
  status business_status NOT NULL,
  changed_by uuid REFERENCES auth.users(id),
  changed_at timestamptz DEFAULT now(),
  notes text
);

-- Add status column to business_profiles
ALTER TABLE business_profiles
ADD COLUMN status business_status NOT NULL DEFAULT 'pending_setup',
ADD COLUMN status_updated_at timestamptz DEFAULT now();

-- Enable RLS
ALTER TABLE business_status_logs ENABLE ROW LEVEL SECURITY;

-- Create policies for status_logs
CREATE POLICY "Super admins can do everything"
  ON business_status_logs
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "Business owners can view their status logs"
  ON business_status_logs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = business_status_logs.business_id
      AND user_roles.user_id = auth.uid()
    )
  );

-- Function to update business status
CREATE OR REPLACE FUNCTION update_business_status(
  business_id uuid,
  new_status business_status,
  notes text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user is super admin
  IF NOT (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean THEN
    RAISE EXCEPTION 'Only super admins can manually update business status';
  END IF;

  -- Update status
  UPDATE business_profiles
  SET 
    status = new_status,
    status_updated_at = now()
  WHERE id = business_id;

  -- Log the change
  INSERT INTO business_status_logs (
    business_id,
    status,
    changed_by,
    notes
  ) VALUES (
    business_id,
    new_status,
    auth.uid(),
    notes
  );
END;
$$;