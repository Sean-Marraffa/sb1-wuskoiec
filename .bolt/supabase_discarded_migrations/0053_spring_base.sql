/*
  # Fix login activity tracking

  1. Changes
    - Simplify login activity tracking to only record successful logins
    - Add better error handling and null checks
    - Fix request headers parsing
    - Add proper security context

  2. Security
    - Function runs with SECURITY DEFINER to ensure proper access
    - Explicit schema references for security
*/

-- Drop existing trigger and function with CASCADE
DROP TRIGGER IF EXISTS after_login ON auth.users CASCADE;
DROP FUNCTION IF EXISTS record_login_activity CASCADE;

-- Create simplified function with better error handling
CREATE OR REPLACE FUNCTION record_login_activity()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
  request_headers jsonb;
BEGIN
  -- Only proceed for successful logins
  IF NEW.last_sign_in_at IS NOT NULL AND OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at THEN
    -- Safely parse request headers
    BEGIN
      request_headers := NULLIF(current_setting('request.headers', true), '')::jsonb;
    EXCEPTION WHEN OTHERS THEN
      request_headers := NULL;
    END;

    -- Insert activity record with safe header access
    INSERT INTO login_activity (
      user_id,
      ip_address,
      user_agent,
      status
    ) VALUES (
      NEW.id,
      COALESCE(request_headers->>'x-real-ip', 'unknown'),
      COALESCE(request_headers->>'user-agent', 'unknown'),
      'success'
    );
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail the trigger
  RAISE WARNING 'Error recording login activity: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- Create trigger for successful logins only
CREATE TRIGGER after_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION record_login_activity();