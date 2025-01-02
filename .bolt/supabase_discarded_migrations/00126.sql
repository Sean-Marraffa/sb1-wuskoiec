-- Drop existing policies\nDROP POLICY IF EXISTS "role_based_select" ON user_roles
DROP POLICY IF EXISTS "owner_manage_team_members" ON user_roles
-- Create simple, non-recursive policies\nCREATE POLICY "enable_select_own_role"\n  ON user_roles\n  FOR SELECT\n  TO authenticated\n  USING (user_id = auth.uid())
CREATE POLICY "enable_owner_select_roles"
  ON user_roles
    FOR SELECT
      TO authenticated
        USING (
              EXISTS (
                      SELECT 1
                            FROM user_roles owner
                                  WHERE owner.user_id = auth.uid()
                                        AND owner.business_id = user_roles.business_id
                                              AND owner.role = 'Account Owner'
                                                    LIMIT 1
                                                        )
                                                          )
CREATE POLICY "enable_owner_manage_team_members"
  ON user_roles
    FOR ALL
      TO authenticated
        USING (
              -- Must be managing a Team Member role\n    role = 'Team Member'\n    AND\n    -- Must be an owner of the business\n    EXISTS (\n      SELECT 1\n      FROM user_roles owner\n      WHERE owner.user_id = auth.uid()\n      AND owner.business_id = user_roles.business_id\n      AND owner.role = 'Account Owner'\n      LIMIT 1\n    )\n  )\n  WITH CHECK (\n    -- Same conditions for inserts/updates\n    role = 'Team Member'\n    AND\n    EXISTS (\n      SELECT 1\n      FROM user_roles owner\n      WHERE owner.user_id = auth.uid()\n      AND owner.business_id = user_roles.business_id\n      AND owner.role = 'Account Owner'\n      LIMIT 1\n    )\n  )
-- Optimize indexes\nDROP INDEX IF EXISTS idx_user_roles_lookup
DROP INDEX IF EXISTS idx_user_roles_owner_lookup


-- Create efficient indexes\nCREATE INDEX idx_user_roles_user_lookup ON user_roles(user_id)

CREATE INDEX idx_user_roles_owner_lookup ON user_roles(user_id, business_id) WHERE role = 'Account Owner'

CREATE INDEX idx_user_roles_team_lookup ON user_roles(business_id, role) WHERE role = 'Team Member'
