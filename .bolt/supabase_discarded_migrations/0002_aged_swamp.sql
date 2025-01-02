/*
  # Configure authentication settings

  1. Changes
    - Disable email confirmation requirement for new signups
    - Allow users to sign in immediately after registration

  Note: This migration updates the auth.users table to auto-confirm all existing and new users
*/

-- Set all existing users as confirmed
UPDATE auth.users 
SET email_confirmed_at = CURRENT_TIMESTAMP 
WHERE email_confirmed_at IS NULL;

-- Create a trigger to auto-confirm email for new users
CREATE OR REPLACE FUNCTION auto_confirm_email()
RETURNS TRIGGER AS $$
BEGIN
  NEW.email_confirmed_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add the trigger to automatically confirm emails for new users
DROP TRIGGER IF EXISTS confirm_user_email ON auth.users;
CREATE TRIGGER confirm_user_email
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION auto_confirm_email();