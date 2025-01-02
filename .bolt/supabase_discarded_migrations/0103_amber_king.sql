-- Drop existing foreign key constraint
ALTER TABLE user_roles
DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;

-- Recreate with CASCADE DELETE
ALTER TABLE user_roles
ADD CONSTRAINT user_roles_user_id_fkey
FOREIGN KEY (user_id)
REFERENCES auth.users(id)
ON DELETE CASCADE;

-- Update delete_user function to handle deletion properly
CREATE OR REPLACE FUNCTION delete_user(user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Check if the executing user is a super admin
  IF NOT (SELECT (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean) THEN
    RAISE EXCEPTION 'Only super admins can delete users';
  END IF;

  -- The CASCADE will automatically handle user_roles deletion
  DELETE FROM auth.users WHERE id = user_id;
END;
$$;