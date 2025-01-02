/*
  # Fix login activity tracking
  
  1. Changes
    - Improve trigger conditions to capture all auth attempts
    - Add better error handling and logging
    - Fix status detection logic
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
DROP FUNCTION IF EXISTS record_login_activity();

-- Create improved function with better auth attempt detection
CREATE OR REPLACE FUNCTION record_login_activity()
RETURNS TRIGGER AS $$
DECLARE
  headers_raw text;
  headers json;
  ip text;
  agent text;
BEGIN
  -- Log the auth attempt details for debugging
  RAISE NOTICE 'Auth attempt detected for user %', NEW.id;
  RAISE NOTICE 'Raw user metadata changed: %', OLD.raw_user_meta_data IS DISTINCT FROM NEW.raw_user_meta_data;
  RAISE NOTICE 'Last sign in changed: %', OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at;
  RAISE NOTICE 'Updated at changed: %', OLD.updated_at IS DISTINCT FROM NEW.updated_at;
  
  -- Get headers with proper error handling
  BEGIN
    headers_raw := NULLIF(current_setting('request.headers', true), '');
    
    IF headers_raw IS NOT NULL THEN
      headers := headers_raw::json;
      -- Extract and sanitize values
      ip := NULLIF(TRIM(REGEXP_REPLACE(headers->>'x-real-ip', '[^0-9\.]', '', 'g')), '');
      agent := NULLIF(TRIM(headers->>'user-agent'), '');
      
      RAISE NOTICE 'Request headers - IP: %, Agent: %', ip, agent;
    ELSE
      RAISE NOTICE 'No request headers found';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error parsing headers: %', SQLERRM;
  END;

  -- Insert activity record with improved status detection
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
      -- Consider it a success if:
      -- 1. last_sign_in_at is updated to a new value
      -- 2. OR if it's a new successful sign in (last_sign_in_at was null and now has a value)
      WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at AND NEW.last_sign_in_at IS NOT NULL)
           OR (OLD.last_sign_in_at IS NULL AND NEW.last_sign_in_at IS NOT NULL)
      THEN 'success'
      -- Otherwise it's a failed attempt
      ELSE 'failed'
    END
  );

  RAISE NOTICE 'Login activity recorded for user %', NEW.id;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Error in record_login_activity: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger with improved conditions
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (
    -- Capture ALL authentication attempts:
    -- 1. Any change to last_sign_in_at (successful logins)
    -- 2. Any change to raw_user_meta_data (failed attempts and other auth changes)
    -- 3. Any change to updated_at (catches other auth-related updates)
    -- 4. Any change to raw_app_meta_data (catches additional auth metadata changes)
    OLD IS DISTINCT FROM NEW AND (
      OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at
      OR OLD.raw_user_meta_data IS DISTINCT FROM NEW.raw_user_meta_data
      OR OLD.updated_at IS DISTINCT FROM NEW.updated_at
      OR OLD.raw_app_meta_data IS DISTINCT FROM NEW.raw_app_meta_data
    )
  )
  EXECUTE FUNCTION record_login_activity();