/*
  # Fix login activity tracking

  1. Changes
    - Add trigger for sign in attempts
    - Improve error handling and logging
    - Add proper indexes
    - Fix activity recording conditions

  2. Security
    - Add input validation
    - Add proper error logging
    - Prevent SQL injection
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
DROP FUNCTION IF EXISTS record_login_activity();

-- Create improved function with better error handling
CREATE OR REPLACE FUNCTION record_login_activity()
RETURNS TRIGGER AS $$
DECLARE
  headers_raw text;
  headers json;
  ip text;
  agent text;
  is_success boolean;
BEGIN
  -- Get headers with proper error handling
  BEGIN
    headers_raw := NULLIF(current_setting('request.headers', true), '');
    
    IF headers_raw IS NOT NULL THEN
      headers := headers_raw::json;
      -- Extract and sanitize values
      ip := NULLIF(TRIM(REGEXP_REPLACE(headers->>'x-real-ip', '[^0-9\.]', '', 'g')), '');
      agent := NULLIF(TRIM(headers->>'user-agent'), '');
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error parsing headers: %', SQLERRM;
  END;

  -- Determine if this is a successful login
  is_success := (
    NEW.last_sign_in_at IS NOT NULL AND 
    (
      OLD.last_sign_in_at IS NULL OR 
      NEW.last_sign_in_at > OLD.last_sign_in_at
    )
  );

  -- Insert activity record
  INSERT INTO login_activity (
    user_id,
    ip_address,
    user_agent,
    status
  ) VALUES (
    NEW.id,
    COALESCE(ip, 'unknown'),
    COALESCE(agent, 'unknown'),
    CASE WHEN is_success THEN 'success' ELSE 'failed' END
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Error in record_login_activity: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that captures all auth attempts
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (
    -- Capture sign in attempts
    OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at
    OR
    -- Capture failed attempts
    (
      OLD.raw_user_meta_data IS DISTINCT FROM NEW.raw_user_meta_data
      AND NEW.last_sign_in_at IS NULL
    )
  )
  EXECUTE FUNCTION record_login_activity();

-- Ensure proper indexes exist
DROP INDEX IF EXISTS idx_login_activity_user_id_status_created;
DROP INDEX IF EXISTS idx_login_activity_ip_address;

CREATE INDEX idx_login_activity_user_id_status_created 
ON login_activity(user_id, status, created_at DESC);

CREATE INDEX idx_login_activity_ip_address 
ON login_activity(ip_address)
WHERE ip_address != 'unknown';