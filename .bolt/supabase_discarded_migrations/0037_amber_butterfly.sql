-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
DROP FUNCTION IF EXISTS record_login_activity();

-- Create improved function to record login activity
CREATE OR REPLACE FUNCTION record_login_activity()
RETURNS TRIGGER AS $$
DECLARE
  headers_raw text;
  headers json;
  ip text;
  agent text;
BEGIN
  -- Safely get headers
  BEGIN
    headers_raw := current_setting('request.headers', true);
    IF headers_raw IS NOT NULL THEN
      headers := headers_raw::json;
      ip := headers->>'x-real-ip';
      agent := headers->>'user-agent';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- If anything fails, continue with null values
    ip := NULL;
    agent := NULL;
  END;

  -- Only record if sign in timestamp changed
  IF OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at THEN
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
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger with better conditions
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION record_login_activity();