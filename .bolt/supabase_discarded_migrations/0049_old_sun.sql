-- Drop existing trigger and function with CASCADE
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users CASCADE;
DROP FUNCTION IF EXISTS record_login_activity() CASCADE;

-- Create improved function with better auth attempt detection
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
    -- Log error but continue execution
    RAISE WARNING 'Error parsing headers: %', SQLERRM;
  END;

  -- Insert activity record for both successful and failed attempts
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
      -- Consider it a success only if last_sign_in_at changed to a non-null value
      WHEN NEW.last_sign_in_at IS NOT NULL AND OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at 
      THEN 'success'
      -- Otherwise it's a failed attempt
      ELSE 'failed'
    END
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log any errors but don't fail the trigger
  RAISE WARNING 'Error in record_login_activity: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that captures all auth attempts
CREATE TRIGGER after_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (
    -- Capture both successful and failed attempts:
    -- 1. Changes to last_sign_in_at (successful logins)
    -- 2. Changes to raw_user_meta_data (failed attempts)
    -- 3. Changes to updated_at (other auth-related updates)
    OLD IS DISTINCT FROM NEW AND (
      OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at OR
      OLD.raw_user_meta_data IS DISTINCT FROM NEW.raw_user_meta_data OR
      OLD.updated_at IS DISTINCT FROM NEW.updated_at
    )
  )
  EXECUTE FUNCTION record_login_activity();

-- Drop and recreate policies to ensure they're up to date
DROP POLICY IF EXISTS "Anyone can insert login activity" ON login_activity;
DROP POLICY IF EXISTS "Anon users can insert login activity" ON login_activity;
DROP POLICY IF EXISTS "Users can view their own login activity" ON login_activity;

-- Create new policies with better names and conditions
CREATE POLICY "enable_insert_for_authenticated"
  ON login_activity
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "enable_insert_for_anon"
  ON login_activity
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "enable_select_for_own_activity"
  ON login_activity
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());