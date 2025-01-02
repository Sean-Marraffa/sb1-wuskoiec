-- Drop existing policies
DROP POLICY IF EXISTS "user_role_access" ON user_roles;
DROP POLICY IF EXISTS "user_role_management" ON user_roles;

-- Create simplified role-based policies
CREATE POLICY "role_based_select"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own roles
    user_id = auth.uid()
    OR
    -- Account Owners can see all roles in their business
    business_id IN (
      SELECT DISTINCT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "owner_manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Only Account Owners can manage Team Members
    EXISTS (
      SELECT 1 
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = user_roles.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    EXISTS (
      SELECT 1 
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = user_roles.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  );

-- Create audit log table for role changes
CREATE TABLE IF NOT EXISTS role_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES business_profiles(id) ON DELETE CASCADE,
  performed_by uuid REFERENCES auth.users(id),
  target_user_id uuid REFERENCES auth.users(id),
  action text NOT NULL,
  old_role text,
  new_role text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on audit logs
ALTER TABLE role_audit_logs ENABLE ROW LEVEL SECURITY;

-- Create policy for audit logs
CREATE POLICY "audit_logs_visible_to_owners"
  ON role_audit_logs
  FOR SELECT
  TO authenticated
  USING (
    business_id IN (
      SELECT DISTINCT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  );

-- Function to log role changes
CREATE OR REPLACE FUNCTION log_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO role_audit_logs (
    business_id,
    performed_by,
    target_user_id,
    action,
    old_role,
    new_role
  ) VALUES (
    NEW.business_id,
    auth.uid(),
    NEW.user_id,
    CASE
      WHEN TG_OP = 'INSERT' THEN 'add_role'
      WHEN TG_OP = 'DELETE' THEN 'remove_role'
      ELSE 'update_role'
    END,
    CASE WHEN TG_OP = 'UPDATE' THEN OLD.role ELSE NULL END,
    CASE WHEN TG_OP != 'DELETE' THEN NEW.role ELSE NULL END
  );
  
  RETURN NEW;
END;
$$;

-- Create trigger for role changes
DROP TRIGGER IF EXISTS role_audit_trigger ON user_roles;
CREATE TRIGGER role_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON user_roles
  FOR EACH ROW
  EXECUTE FUNCTION log_role_change();

-- Optimize indexes
DROP INDEX IF EXISTS idx_user_roles_lookup;
DROP INDEX IF EXISTS idx_user_roles_owner_lookup;

CREATE INDEX idx_user_roles_efficient 
ON user_roles(user_id, business_id, role);

CREATE INDEX idx_user_roles_owner_lookup 
ON user_roles(user_id, business_id) 
WHERE role = 'Account Owner';

CREATE INDEX idx_role_audit_logs_business 
ON role_audit_logs(business_id, created_at DESC);