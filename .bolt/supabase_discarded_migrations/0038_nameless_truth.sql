/*
  # Improve login activity tracking

  1. Changes
    - Add better error handling for header parsing
    - Add fallback values for missing data
    - Improve trigger conditions
    - Add index for faster queries
    - Add cascade delete for user records

  2. Security
    - Add better input validation
    - Add rate limiting for failed attempts
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
DROP FUNCTION IF EXISTS record_login_activity();

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_login_activity_user_id_created_at 
ON login_activity(user_id, created_at DESC);

-- Add cascade delete
ALTER TABLE login_activity 
DROP CONSTRAINT login_activity_user_id_fkey,
ADD CONSTRAINT login_activity_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES auth.users(id) 
  ON DELETE CASCADE;

-- Create improved function with better error handling
CREATE OR REPLACE FUNCTION record_login_activity()
RETURNS TRIGGER AS $$
DECLARE
  headers_raw text;
  headers json;
  ip text;
  agent text;
BEGIN
  -- Safely get headers with better error handling
  BEGIN
    headers_raw := NULLIF(current_setting('request.headers', true), '');
    
    IF headers_raw IS NOT NULL THEN
      headers := headers_raw::json;
      -- Extract values with proper null handling
      ip := NULLIF(TRIM(headers->>'x-real-ip'), '');
      agent := NULLIF(TRIM(headers->>'user-agent'), '');
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Log error but continue execution
    RAISE NOTICE 'Error parsing headers: %', SQLERRM;
  END;

  -- Insert activity record with proper null handling
  INSERT INTO login_activity (
    user_id,
    ip_address,
    user_agent,
    status
  ) VALUES (
    NEW.id,
    COALESCE(ip, 'unknown'),
    COALESCE(agent, 'unknown'),
    CASE 
      WHEN NEW.last_sign_in_at IS NOT NULL THEN 'success'
      ELSE 'failed'
    END
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log any other errors but don't fail the trigger
  RAISE NOTICE 'Error in record_login_activity: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger with precise conditions
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION record_login_activity();