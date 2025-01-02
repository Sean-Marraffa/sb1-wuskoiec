\n\n-- Drop existing policies\nDROP POLICY IF EXISTS "business_profiles_super_admin" ON business_profiles
\nDROP POLICY IF EXISTS "business_profiles_setup" ON business_profiles
\nDROP POLICY IF EXISTS "business_profiles_view" ON business_profiles
\nDROP POLICY IF EXISTS "business_profiles_manage" ON business_profiles
\nDROP POLICY IF EXISTS "user_roles_super_admin" ON user_roles
\nDROP POLICY IF EXISTS "user_roles_setup" ON user_roles
\n\n-- Business profiles policies\nCREATE POLICY "super_admin_view"\n  ON business_profiles\n  FOR SELECT\n  TO authenticated\n  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
\n\nCREATE POLICY "user_create_during_setup"\n  ON business_profiles\n  FOR INSERT\n  TO authenticated\n  WITH CHECK (\n    (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true\n    AND NOT (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean\n  )
\n\nCREATE POLICY "user_view_own"\n  ON business_profiles\n  FOR SELECT\n  TO authenticated\n  USING (\n    EXISTS (\n      SELECT 1 FROM user_roles\n      WHERE user_roles.business_id = id\n      AND user_roles.user_id = auth.uid()\n    )\n  )
\n\nCREATE POLICY "owner_manage"\n  ON business_profiles\n  FOR ALL\n  TO authenticated\n  USING (\n    EXISTS (\n      SELECT 1 FROM user_roles\n      WHERE user_roles.business_id = id\n      AND user_roles.user_id = auth.uid()\n      AND user_roles.role = 'Account Owner'\n    )\n  )\n  WITH CHECK (\n    EXISTS (\n      SELECT 1 FROM user_roles\n      WHERE user_roles.business_id = id\n      AND user_roles.user_id = auth.uid()\n      AND user_roles.role = 'Account Owner'\n    )\n  )
\n\n-- User roles policies\nCREATE POLICY "create_initial_role"\n  ON user_roles\n  FOR INSERT\n  TO authenticated\n  WITH CHECK (\n    user_id = auth.uid()\n    AND (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true\n    AND NOT (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean\n  )
\n\nCREATE POLICY "view_own_roles"\n  ON user_roles\n  FOR SELECT\n  TO authenticated\n  USING (\n    user_id = auth.uid()\n    OR (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true\n  )
