-- Drop existing trigger and function
DROP TRIGGER IF EXISTS after_login ON auth.users CASCADE;
DROP FUNCTION IF EXISTS record_login_activity() CASCADE;

-- Create simplified function that only tracks successful logins
CREATE OR REPLACE FUNCTION record_login_activity()
RETURNS TRIGGER AS $$
BEGIN
  -- Only record successful logins (when last_sign_in_at changes)
  IF OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at AND NEW.last_sign_in_at IS NOT NULL THEN
    INSERT INTO login_activity (
      user_id,
      ip_address,
      user_agent,
      status
    ) VALUES (
      NEW.id,
      COALESCE(current_setting('request.headers', true)::json->>'x-real-ip', 'unknown'),
      COALESCE(current_setting('request.headers', true)::json->>'user-agent', 'unknown'),
      'success'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that only fires on last_sign_in_at changes
CREATE TRIGGER after_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION record_login_activity();