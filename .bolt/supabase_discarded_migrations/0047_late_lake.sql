-- Drop existing trigger and function with CASCADE to handle dependencies
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users CASCADE;
DROP FUNCTION IF EXISTS record_login_activity() CASCADE;

-- Create improved function with better auth attempt detection
CREATE OR REPLACE FUNCTION record_login_activity()
RETURNS TRIGGER AS $$
BEGIN
  -- Only record if sign in timestamp changed
  IF OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at THEN
    INSERT INTO login_activity (
      user_id,
      ip_address,
      user_agent,
      status
    ) VALUES (
      NEW.id,
      current_setting('request.headers', true)::json->>'x-real-ip',
      current_setting('request.headers', true)::json->>'user-agent',
      CASE 
        WHEN NEW.last_sign_in_at IS NOT NULL THEN 'success'
        ELSE 'failed'
      END
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger with precise conditions
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION record_login_activity();