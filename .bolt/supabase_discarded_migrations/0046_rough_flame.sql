-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can insert login activity" ON login_activity;
DROP POLICY IF EXISTS "Anon users can insert login activity" ON login_activity;
DROP POLICY IF EXISTS "Users can view their own login activity" ON login_activity;

-- Create new policies
CREATE POLICY "Anyone can insert login activity"
  ON login_activity
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Anon users can insert login activity"
  ON login_activity
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Users can view their own login activity"
  ON login_activity
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());