/*
  # Add Business Users RLS Policies

  1. Security Changes
    - Enable RLS on business_users table
    - Add policies for:
      - Creating business user associations
      - Reading business user records
      - Updating business user records
      - Deleting business user records
    
  2. Notes
    - Policies ensure users can only manage business users for businesses they own
    - Account Owners can manage all users for their business
    - Users can read their own associations
*/

-- Enable RLS
ALTER TABLE business_users ENABLE ROW LEVEL SECURITY;

-- Policy for creating business user associations
CREATE POLICY "Users can create business associations during onboarding"
  ON business_users
  FOR INSERT
  WITH CHECK (
    -- Allow during onboarding when user has pending_business_id
    auth.uid() IN (
      SELECT au.id 
      FROM auth.users au
      WHERE au.id = auth.uid() 
      AND (au.raw_user_meta_data->>'pending_business_id')::uuid = business_id
    )
    OR
    -- Allow Account Owners to add users
    EXISTS (
      SELECT 1 
      FROM business_users bu
      WHERE bu.business_id = business_users.business_id
      AND bu.user_id = auth.uid()
      AND bu.role = 'Account Owner'
    )
  );

-- Policy for reading business user records
CREATE POLICY "Users can read their own business associations"
  ON business_users
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR
    -- Account Owners can see all users in their business
    EXISTS (
      SELECT 1 
      FROM business_users bu
      WHERE bu.business_id = business_users.business_id
      AND bu.user_id = auth.uid()
      AND bu.role = 'Account Owner'
    )
  );

-- Policy for updating business user records
CREATE POLICY "Account Owners can update business user records"
  ON business_users
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 
      FROM business_users bu
      WHERE bu.business_id = business_users.business_id
      AND bu.user_id = auth.uid()
      AND bu.role = 'Account Owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM business_users bu
      WHERE bu.business_id = business_users.business_id
      AND bu.user_id = auth.uid()
      AND bu.role = 'Account Owner'
    )
  );

-- Policy for deleting business user records
CREATE POLICY "Account Owners can delete business user records"
  ON business_users
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 
      FROM business_users bu
      WHERE bu.business_id = business_users.business_id
      AND bu.user_id = auth.uid()
      AND bu.role = 'Account Owner'
    )
  );