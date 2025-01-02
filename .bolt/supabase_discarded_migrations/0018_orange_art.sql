/*
  # Add super admin management policies
  
  1. Changes
    - Add policy for super admins to manage business profiles
    - Add policy for super admins to manage user roles
  
  2. Security
    - Maintain existing RLS
    - Add full access policies for super admins
*/

-- Add super admin management policy for business profiles
CREATE POLICY "super_admin_manage"
  ON business_profiles
  FOR ALL
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

-- Add super admin management policy for user roles
CREATE POLICY "super_admin_manage_roles"
  ON user_roles
  FOR ALL
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);