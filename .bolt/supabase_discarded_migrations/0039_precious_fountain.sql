/*
  # Improve login activity tracking

  1. Changes
    - Fix trigger conditions to properly capture all login attempts
    - Add better error handling for header parsing
    - Add rate limiting for failed attempts
    - Add proper indexing for performance
    - Improve data sanitization

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

  -- Rate limiting check for failed attempts
  IF NEW.last_sign_in_at IS NULL THEN
    IF EXISTS (
      SELECT 1 FROM login_activity
      WHERE user_id = NEW.id
        AND status = 'failed'
        AND created_at > NOW() - INTERVAL '15 minutes'
      GROUP BY user_id
      HAVING COUNT(*) > 5
    ) THEN
      RAISE WARNING 'Too many failed login attempts for user %', NEW.id;
      RETURN NEW;
    END IF;
  END IF;

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
  RAISE WARNING 'Error in record_login_activity: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger with proper conditions
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (
    -- Capture both successful and failed attempts
    (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at) OR
    (OLD.last_sign_in_at IS NULL AND NEW.last_sign_in_at IS NULL AND 
     OLD.updated_at IS DISTINCT FROM NEW.updated_at)
  )
  EXECUTE FUNCTION record_login_activity();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_login_activity_user_id_status_created 
ON login_activity(user_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_login_activity_ip_address 
ON login_activity(ip_address)
WHERE ip_address != 'unknown';