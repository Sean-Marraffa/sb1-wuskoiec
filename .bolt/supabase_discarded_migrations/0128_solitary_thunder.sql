-- Drop all existing policies\nDROP POLICY IF EXISTS "role_select_policy" ON user_roles
\nDROP POLICY IF EXISTS "team_member_policy" ON user_roles
\nDROP POLICY IF EXISTS "basic_select_policy" ON user_roles
\nDROP POLICY IF EXISTS "owner_select_policy" ON user_roles
\nDROP POLICY IF EXISTS "owner_manage_policy" ON user_roles
\n\n-- Create simple, non-recursive policies\nCREATE POLICY "select_roles"\n  ON user_roles\n  FOR SELECT\n  TO authenticated\n  USING (\n    -- Users can see their own roles\n    user_id = auth.uid()\n    OR\n    -- Users can see roles in businesses where they are an owner\n    business_id IN (\n      SELECT DISTINCT business_id \n      FROM user_roles \n      WHERE user_id = auth.uid() \n      AND role = 'Account Owner'\n    )\n  )
\n\nCREATE POLICY "manage_roles"\n  ON user_roles\n  FOR ALL\n  TO authenticated\n  USING (\n    -- Must be managing a team member role\n    role = 'Team Member'\n    AND\n    -- Must be an owner of the business\n    business_id IN (\n      SELECT DISTINCT business_id \n      FROM user_roles \n      WHERE user_id = auth.uid() \n      AND role = 'Account Owner'\n    )\n  )\n  WITH CHECK (\n    -- Same conditions for inserts/updates\n    role = 'Team Member'\n    AND\n    business_id IN (\n      SELECT DISTINCT business_id \n      FROM user_roles \n      WHERE user_id = auth.uid() \n      AND role = 'Account Owner'\n    )\n  )
\n\n-- Create optimized indexes\nDROP INDEX IF EXISTS idx_user_roles_access_v3
\nDROP INDEX IF EXISTS idx_user_roles_owner_v3
\n\nCREATE INDEX idx_user_roles_lookup_v4 ON user_roles(user_id, business_id, role)
\nCREATE INDEX idx_user_roles_owner_v4 ON user_roles(user_id, business_id) WHERE role = 'Account Owner'