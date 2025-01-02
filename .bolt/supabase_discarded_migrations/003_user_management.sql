/*
  # Authentication and Team Management

  1. Tables
    - auth.users: Stores user authentication data
    - team_invites: Tracks invitations to join teams
    - audit_logs: Logs actions for auditing purposes

  2. Functions
    - invite_team_member: Creates invite records
    - handle_invite_acceptance: Processes accepted invites
    - remove_team_member: Removes a team member from a business
    - cancel_team_invite: Cancels pending team invites

  3. Security
    - RLS enabled on team_invites and audit_logs
    - Policies for role-based access control
    - Function permissions granted to appropriate roles

  4. Schema Settings
    - Search paths configured for auth-related functions

  5. Triggers
    - on_auth_user_created: Handles new user creation workflows
*/

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA auth TO anon;

-- Grant select permissions on key auth tables
GRANT SELECT ON auth.users TO authenticated;
GRANT SELECT ON auth.users TO anon;

/*
  # Fix authentication permissions and schema settings
*/

-- Grant schema and table permissions
GRANT USAGE ON SCHEMA extensions TO authenticated;
GRANT USAGE ON SCHEMA extensions TO anon;
GRANT SELECT ON auth.refresh_tokens TO authenticated;
GRANT SELECT ON auth.refresh_tokens TO anon;
GRANT SELECT ON auth.sessions TO authenticated;
GRANT SELECT ON auth.sessions TO anon;

-- Grant execute permissions on additional auth functions
GRANT EXECUTE ON FUNCTION auth.email() TO anon;
GRANT EXECUTE ON FUNCTION auth.uid() TO anon;
GRANT EXECUTE ON FUNCTION auth.role() TO anon;
GRANT EXECUTE ON FUNCTION auth.jwt() TO anon;

-- Ensure correct search paths for auth-related functions
ALTER FUNCTION auth.email() SET search_path = auth, extensions, public;
ALTER FUNCTION auth.uid() SET search_path = auth, extensions, public;
ALTER FUNCTION auth.role() SET search_path = auth, extensions, public;
ALTER FUNCTION auth.jwt() SET search_path = auth, extensions, public;

/*
  # Team Member Invite System
*/

-- Create team invites table
CREATE TABLE team_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    invite_token UUID NOT NULL DEFAULT gen_random_uuid(),
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '7 days')
);

-- Enable RLS and create indexes
ALTER TABLE team_invites ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_team_invites_business ON team_invites(business_id);
CREATE INDEX idx_team_invites_email ON team_invites(email);
CREATE INDEX idx_team_invites_token ON team_invites(invite_token);

-- Create policies
CREATE POLICY "Users can view their business invites"
    ON team_invites
    FOR SELECT
    USING (
        business_id IN (
            SELECT business_id 
            FROM business_users 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Account owners can manage invites"
    ON team_invites
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = team_invites.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = team_invites.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    );

-- Create invite team member function
CREATE OR REPLACE FUNCTION invite_team_member(
    p_business_id UUID,
    p_email TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = extensions, public, auth
AS $$
DECLARE
    v_owner_role TEXT;
    v_invite_id UUID;
    v_invite_token UUID;
BEGIN
    -- Check if caller is business owner
    SELECT role INTO v_owner_role
    FROM business_users
    WHERE business_id = p_business_id
    AND user_id = auth.uid()
    AND role = 'Account Owner';

    IF v_owner_role IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Unauthorized: Only Account Owners can invite team members'
        );
    END IF;

    -- Check if email already has a pending invite
    IF EXISTS (
        SELECT 1 FROM team_invites
        WHERE business_id = p_business_id
        AND email = p_email
        AND status = 'pending'
        AND expires_at > now()
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'An active invite already exists for this email'
        );
    END IF;

    -- Create new invite
    v_invite_token := gen_random_uuid();
    INSERT INTO team_invites (
        business_id,
        email,
        invite_token
    ) VALUES (
        p_business_id,
        p_email,
        v_invite_token
    )
    RETURNING id INTO v_invite_id;

    RETURN jsonb_build_object(
        'success', true,
        'invite_id', v_invite_id,
        'invite_token', v_invite_token
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Unexpected error: ' || SQLERRM
    );
END;
$$;

/*
  # Add Trigger for Team Member Invite Acceptance
*/

-- Create the trigger function
CREATE OR REPLACE FUNCTION handle_invite_acceptance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_invite RECORD;
BEGIN
  -- Check if user was created with an invite token
  IF NEW.raw_user_meta_data->>'invite_token' IS NOT NULL THEN
    -- Get the invite
    SELECT * INTO v_invite
    FROM team_invites
    WHERE invite_token = (NEW.raw_user_meta_data->>'invite_token')::uuid
    AND status = 'pending'
    AND expires_at > now();

    IF v_invite IS NULL THEN
      RAISE EXCEPTION 'Invalid or expired invite token';
    END IF;

    -- Add user to business_users
    INSERT INTO business_users (
      user_id,
      business_id,
      role
    ) VALUES (
      NEW.id,
      v_invite.business_id,
      'Team Member'
    );

    -- Update invite status
    UPDATE team_invites
    SET status = 'accepted'
    WHERE id = v_invite.id;
  END IF;

  RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_invite_acceptance();

/*
  # Add team member management functions
*/

-- Create audit_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action TEXT NOT NULL,
    business_id UUID NOT NULL REFERENCES businesses(id),
    performed_by UUID NOT NULL,
    target_user_id UUID,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on audit_logs
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Create policy for audit_logs
CREATE POLICY "Users can view their business audit logs" ON audit_logs
    FOR SELECT
    USING (business_id IN (
        SELECT business_id FROM business_users WHERE user_id = auth.uid()
    ));

-- Function to remove team member
CREATE OR REPLACE FUNCTION remove_team_member(
    p_business_id UUID,
    p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_owner_role TEXT;
    v_target_role TEXT;
BEGIN
    -- Check if caller is business owner
    SELECT role INTO v_owner_role
    FROM business_users
    WHERE business_id = p_business_id
    AND user_id = auth.uid()
    AND role = 'Account Owner';

    IF v_owner_role IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Unauthorized: Only Account Owners can remove team members'
        );
    END IF;

    -- Check target user's role
    SELECT role INTO v_target_role
    FROM business_users
    WHERE business_id = p_business_id
    AND user_id = p_user_id;

    IF v_target_role IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User is not a member of this business'
        );
    END IF;

    IF v_target_role = 'Account Owner' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Cannot remove Account Owner'
        );
    END IF;

    -- Remove the team member
    DELETE FROM business_users
    WHERE business_id = p_business_id
    AND user_id = p_user_id;

    -- Log the action
    INSERT INTO audit_logs (
        action,
        business_id,
        performed_by,
        target_user_id,
        details
    ) VALUES (
        'remove_team_member',
        p_business_id,
        auth.uid(),
        p_user_id,
        jsonb_build_object('role', v_target_role)
    );

    RETURN jsonb_build_object(
        'success', true
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Unexpected error: ' || SQLERRM
    );
END;
$$;

-- Function to cancel team invite
CREATE OR REPLACE FUNCTION cancel_team_invite(
    p_business_id UUID,
    p_invite_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_owner_role TEXT;
    v_invite RECORD;
BEGIN
    -- Check if caller is business owner
    SELECT role INTO v_owner_role
    FROM business_users
    WHERE business_id = p_business_id
    AND user_id = auth.uid()
    AND role = 'Account Owner';

    IF v_owner_role IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Unauthorized: Only Account Owners can cancel invites'
        );
    END IF;

    -- Get invite details for logging
    SELECT * INTO v_invite
    FROM team_invites
    WHERE id = p_invite_id
    AND business_id = p_business_id
    AND status = 'pending';

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Invite not found or already processed'
        );
    END IF;

    -- Update invite status
    UPDATE team_invites
    SET status = 'cancelled'
    WHERE id = p_invite_id;

    -- Log the action
    INSERT INTO audit_logs (
        action,
        business_id,
        performed_by,
        details
    ) VALUES (
        'cancel_team_invite',
        p_business_id,
        auth.uid(),
        jsonb_build_object('email', v_invite.email)
    );

    RETURN jsonb_build_object(
        'success', true
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Unexpected error: ' || SQLERRM
    );
END;
$$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION remove_team_member TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_team_invite TO authenticated;

/*
  # Remove Unused Password Verification Function

  Removes the verify_user_password function since authentication is handled
  by Supabase Auth service directly.
*/

DROP FUNCTION IF EXISTS verify_user_password(text, text);

/*
  # Remove Unused Team Member Creation Function

  Removes the create_team_member function as it is not used in the current schema.
*/

DROP FUNCTION IF EXISTS create_team_member(UUID, TEXT, TEXT, TEXT);
