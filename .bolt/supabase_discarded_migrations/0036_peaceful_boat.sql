/*
  # Add login activity tracking

  1. New Tables
    - `login_activity`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `ip_address` (text)
      - `user_agent` (text)
      - `status` (text) - 'success' or 'failed'
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS
    - Add policy for users to view their own login activity
*/

-- Create login activity table
CREATE TABLE login_activity (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  ip_address text,
  user_agent text,
  status text NOT NULL CHECK (status IN ('success', 'failed')),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE login_activity ENABLE ROW LEVEL SECURITY;

-- Create policy for users to view their own login activity
CREATE POLICY "Users can view their own login activity"
  ON login_activity
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Function to record login activity
CREATE OR REPLACE FUNCTION record_login_activity()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO login_activity (
    user_id,
    ip_address,
    user_agent,
    status
  ) VALUES (
    NEW.id,
    current_setting('request.headers')::json->>'x-real-ip',
    current_setting('request.headers')::json->>'user-agent',
    CASE 
      WHEN NEW.last_sign_in_at IS NOT NULL THEN 'success'
      ELSE 'failed'
    END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to record login activity
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION record_login_activity();