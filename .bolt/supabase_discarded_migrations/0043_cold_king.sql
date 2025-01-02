/*
  # Add login activity debugging
  
  1. Changes
    - Add debug logging to login activity trigger
    - Add more precise condition checks
    - Improve error handling
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
DROP FUNCTION IF EXISTS record_login_activity();

-- Create improved function with debug logging
CREATE OR REPLACE FUNCTION record_login_activity()
RETURNS TRIGGER AS $$
DECLARE
  headers_raw text;
  headers json;
  ip text;
  agent text;
BEGIN
  -- Log the auth attempt
  RAISE NOTICE 'Auth attempt detected for user %', NEW.id;
  RAISE NOTICE 'Old sign in: %, New sign in: %', OLD.last_sign_in_at, NEW.last_sign_in_at;
  RAISE NOTICE 'Old updated: %, New updated: %', OLD.updated_at, NEW.updated_at;
  
  -- Get headers with proper error handling
  BEGIN
    headers_raw := NULLIF(current_setting('request.headers', true), '');
    
    IF headers_raw IS NOT NULL THEN
      headers := headers_raw::json;
      -- Extract and sanitize values
      ip := NULLIF(TRIM(REGEXP_REPLACE(headers->>'x-real-ip', '[^0-9\.]', '', 'g')), '');
      agent := NULLIF(TRIM(headers->>'user-agent'), '');
      
      -- Log headers
      RAISE NOTICE 'Headers found - IP: %, Agent: %', ip, agent;
    ELSE
      RAISE NOTICE 'No headers found in request';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error parsing headers: %', SQLERRM;
  END;

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
    CASE 
      -- Check if this is a new successful login
      WHEN NEW.last_sign_in_at IS NOT NULL AND 
           (OLD.last_sign_in_at IS NULL OR NEW.last_sign_in_at > OLD.last_sign_in_at)
      THEN 'success'
      ELSE 'failed'
    END
  ) RETURNING id, status INTO headers_raw;  -- Reuse variable to avoid declaring new one
  
  RAISE NOTICE 'Login activity recorded: % with status %', headers_raw, CASE 
    WHEN NEW.last_sign_in_at IS NOT NULL AND 
         (OLD.last_sign_in_at IS NULL OR NEW.last_sign_in_at > OLD.last_sign_in_at)
    THEN 'success'
    ELSE 'failed'
  END;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Error in record_login_activity: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger with more precise conditions
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (
    -- Capture any authentication attempt by checking multiple conditions
    OLD IS DISTINCT FROM NEW AND (
      -- Successful login (last_sign_in_at changed)
      OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at
      OR
      -- Failed attempt (metadata changed but no successful login)
      (OLD.raw_user_meta_data IS DISTINCT FROM NEW.raw_user_meta_data)
      OR
      -- Catch other auth-related changes
      (OLD.updated_at IS DISTINCT FROM NEW.updated_at)
    )
  )
  EXECUTE FUNCTION record_login_activity();