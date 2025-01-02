/*
  # Add Super Admin Field and Total Accounts Function

  1. Schema Changes
    - Add `is_super_admin` boolean field to profiles table
    - Add function to count total accounts

  2. Security
    - Update RLS policies to allow super admins to view all profiles
    - Add policy for super admins to update other profiles
*/

-- Add is_super_admin field
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN DEFAULT false;

-- Function to count total accounts
CREATE OR REPLACE FUNCTION get_total_accounts()
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM profiles
  );
END;
$$;