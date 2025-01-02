-- Drop problematic policies
DROP POLICY IF EXISTS "user_role_select_v5" ON user_roles;
DROP POLICY IF EXISTS "user_role_manage_v5" ON user_roles;

-- Drop indexes
DROP INDEX IF EXISTS idx_user_roles_lookup_v5;
DROP INDEX IF EXISTS idx_user_roles_owner_v5;

-- Drop the old table since we've migrated to business_memberships
DROP TABLE IF EXISTS user_roles CASCADE;