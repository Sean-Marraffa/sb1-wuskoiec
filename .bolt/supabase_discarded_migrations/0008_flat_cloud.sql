/*
  # Add RLS policies for business profile creation

  1. Changes
    - Add INSERT policy for business_profiles table to allow authenticated users to create profiles
    - Add INSERT policy for user_roles table to allow authenticated users to create roles

  2. Security
    - Only authenticated users can create business profiles
    - Users can only create roles for themselves
*/

-- Policy for creating business profiles
CREATE POLICY "Users can create business profiles"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy for creating user roles
CREATE POLICY "Users can create their own roles"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());