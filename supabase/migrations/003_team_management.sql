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

-- Ensure service role has proper access
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO service_role;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA auth TO anon;

-- Grant select permissions on key auth tables
GRANT SELECT ON auth.users TO authenticated;
GRANT SELECT ON auth.users TO anon;

-- Grant access to sequence
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
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
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '7 days')
);


-- Enable RLS and create indexes
ALTER TABLE team_invites FORCE ROW LEVEL SECURITY;
ALTER TABLE team_invites ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions to service role
GRANT ALL ON team_invites TO service_role;
GRANT SELECT, UPDATE ON team_invites TO anon;
GRANT SELECT, UPDATE ON team_invites TO authenticated;

ALTER TABLE team_invites FORCE ROW LEVEL SECURITY;
ALTER TABLE team_invites ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_team_invites_business ON team_invites(business_id);
CREATE INDEX IF NOT EXISTS idx_team_invites_email ON team_invites(email);
CREATE INDEX IF NOT EXISTS idx_team_invites_token ON team_invites(invite_token);

-- Add indexes to optimize team invite lookups and prevent transaction timeouts
CREATE INDEX IF NOT EXISTS idx_team_invites_token_status ON team_invites(invite_token) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_team_invites_email_status ON team_invites(email) WHERE status = 'pending';

-- Add index for expires_at to help with cleanup
CREATE INDEX IF NOT EXISTS idx_team_invites_expires_at ON team_invites(expires_at) WHERE status = 'pending';

-- Add composite index for common lookup pattern
CREATE INDEX IF NOT EXISTS idx_team_invites_status_expires ON team_invites(status, expires_at) 
WHERE status = 'pending';

-- Add helpful comment
COMMENT ON INDEX idx_team_invites_token_status IS 'Optimizes lookup of pending invites by token';
COMMENT ON INDEX idx_team_invites_email_status IS 'Optimizes lookup of pending invites by email';
COMMENT ON INDEX idx_team_invites_expires_at IS 'Helps with expired invite cleanup';
COMMENT ON INDEX idx_team_invites_status_expires IS 'Optimizes combined status and expiration checks';

-- Create policies
CREATE OR REPLACE FUNCTION update_team_invites_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_team_invites_updated_at
  BEFORE UPDATE ON team_invites
  FOR EACH ROW
  EXECUTE FUNCTION update_team_invites_updated_at();

-- Add helpful comment
COMMENT ON COLUMN team_invites.updated_at IS 'Timestamp of last update to the invite';
COMMENT ON TRIGGER update_team_invites_updated_at ON team_invites IS 'Updates updated_at timestamp before each update';

-- Add policy for trigger function
CREATE POLICY "trigger_function_policy"
    ON team_invites
    FOR ALL
    TO postgres
    USING (true)
    WITH CHECK (true);

-- Add helpful comment
COMMENT ON POLICY "trigger_function_policy" ON team_invites IS 'Allows trigger function to bypass RLS';

-- Create comprehensive policies for team invites
CREATE POLICY "team_invites_select_policy"
    ON team_invites
    FOR SELECT
    TO public
    USING (
        (status = 'pending' AND expires_at > now())
        OR 
        business_id IN (
            SELECT business_id 
            FROM business_users 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "team_invites_update_policy"
    ON team_invites
    FOR UPDATE
    USING (status = 'pending' AND expires_at > now())
    WITH CHECK (true);

CREATE POLICY "team_invites_service_role_policy"
    ON team_invites
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow team member creation"
    ON business_users
    FOR INSERT
    TO public
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM team_invites 
            WHERE business_id = business_users.business_id
            AND status = 'pending'
            AND expires_at > now()
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



-- Add helpful comment
COMMENT ON TABLE team_invites IS 'Stores team member invitations with secure token-based access';

-- Create function to get team members
CREATE OR REPLACE FUNCTION get_team_members(
    p_business_id UUID
)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    full_name TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Check if caller has access to the business
    IF NOT EXISTS (
        SELECT 1 
        FROM business_users bu
        WHERE bu.business_id = p_business_id 
        AND bu.user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Not authorized to view team members for this business';
    END IF;

    RETURN QUERY
    SELECT 
        au.id::UUID as user_id,
        au.email::TEXT,
        COALESCE(au.raw_user_meta_data->>'full_name', au.email)::TEXT as full_name,
        bu.created_at::TIMESTAMPTZ
    FROM business_users bu
    JOIN auth.users au ON au.id = bu.user_id
    WHERE bu.business_id = p_business_id
    ORDER BY bu.created_at DESC;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_team_members TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION get_team_members IS 'Returns list of team members for a business with proper timestamp handling and authorization checks';

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

-- Create function to safely check if user exists
CREATE OR REPLACE FUNCTION check_user_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM auth.users 
        WHERE email = p_email
    );
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION check_user_exists TO anon;
GRANT EXECUTE ON FUNCTION check_user_exists TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION check_user_exists IS 'Safely checks if a user exists by email without exposing sensitive data';

-- Create function to handle existing user invite acceptance
CREATE OR REPLACE FUNCTION accept_team_invite(
    p_invite_token UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_invite RECORD;
    v_user_id UUID;
    v_business_id UUID;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Not authenticated'
        );
    END IF;

    -- Get and validate invite in a subtransaction
    BEGIN
        SELECT i.*, b.id as business_id 
        INTO STRICT v_invite
        FROM team_invites i
        JOIN businesses b ON b.id = i.business_id
        WHERE i.invite_token = p_invite_token
            AND i.status = 'pending'
            AND i.expires_at > now();

        -- Store business_id for later use
        v_business_id := v_invite.business_id;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Invalid or expired invite'
            );
        WHEN TOO_MANY_ROWS THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Multiple invites found - please contact support'
            );
        WHEN OTHERS THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Error validating invite: ' || SQLERRM
            );
    END;

    -- Verify email matches in a subtransaction
    DECLARE
        v_user_email TEXT;
    BEGIN
        SELECT email INTO STRICT v_user_email 
        FROM auth.users 
        WHERE id = v_user_id;

        IF v_invite.email != v_user_email THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'This invite is for a different email address'
            );
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Error verifying user email: ' || SQLERRM
        );
    END;

    -- Create team member relationship in a subtransaction
    BEGIN
        INSERT INTO business_users (
            user_id,
            business_id,
            role,
            is_default
        ) VALUES (
            v_user_id,
            v_business_id,
            'Team Member',
            true
        );
    EXCEPTION 
        WHEN unique_violation THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'You are already a member of this business'
            );
        WHEN OTHERS THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Error creating team member: ' || SQLERRM
            );
    END;

    -- Update invite status in a subtransaction
    BEGIN
        UPDATE team_invites
        SET status = 'accepted',
            updated_at = now()
        WHERE id = v_invite.id;
    EXCEPTION WHEN OTHERS THEN
        -- Log error but don't fail the transaction
        RAISE LOG 'Error updating invite status: %', SQLERRM;
    END;

    -- Add audit log in a subtransaction
    BEGIN
        INSERT INTO audit_logs (
            action,
            business_id,
            performed_by,
            target_user_id,
            details
        ) VALUES (
            'accept_team_invite',
            v_business_id,
            v_user_id,
            v_user_id,
            jsonb_build_object(
                'invite_id', v_invite.id,
                'email', v_invite.email,
                'method', 'existing_user'
            )
        );
    EXCEPTION WHEN OTHERS THEN
        -- Log error but don't fail the transaction
        RAISE LOG 'Error creating audit log: %', SQLERRM;
    END;

    RETURN jsonb_build_object(
        'success', true,
        'business_id', v_business_id
    );
END;
$$;

-- Add helpful comment
COMMENT ON FUNCTION accept_team_invite IS 'Handles team invite acceptance for existing users with improved error handling';

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION accept_team_invite TO authenticated;

/*
  # Add Trigger for Team Member Invite Acceptance
*/

-- Update the trigger function with better transaction handling
CREATE OR REPLACE FUNCTION handle_invite_acceptance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_invite RECORD;
  v_business_id UUID;
BEGIN
  -- Only proceed if user was created with an invite token
  IF NEW.raw_user_meta_data->>'invite_token' IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get the invite within its own subtransaction
  BEGIN
    SELECT i.*, b.id as business_id 
    INTO v_invite
    FROM team_invites i
    JOIN businesses b ON b.id = i.business_id
    WHERE i.invite_token = (NEW.raw_user_meta_data->>'invite_token')::uuid
      AND i.status = 'pending'
      AND i.expires_at > now();

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Invalid or expired invite token';
    END IF;

    -- Store business_id for later use
    v_business_id := v_invite.business_id;
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error validating invite: %', SQLERRM;
    RETURN NEW;
  END;

  -- Create team member relationship
  BEGIN
    INSERT INTO business_users (
      user_id,
      business_id,
      role,
      is_default
    ) VALUES (
      NEW.id,
      v_business_id,
      'Team Member',
      true
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error creating team member: %', SQLERRM;
    RETURN NEW;
  END;

  -- Update invite status
  BEGIN
    UPDATE team_invites
    SET status = 'accepted',
        updated_at = now()
    WHERE id = v_invite.id;
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error updating invite status: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$;

-- Update the handle_invite_acceptance function to be more permissive
ALTER FUNCTION handle_invite_acceptance() SECURITY DEFINER;
ALTER FUNCTION handle_invite_acceptance() RESET search_path;
ALTER FUNCTION handle_invite_acceptance() SET search_path TO public, auth;




-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_invite_acceptance();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION handle_invite_acceptance() TO postgres;
GRANT EXECUTE ON FUNCTION handle_invite_acceptance() TO service_role;
GRANT EXECUTE ON FUNCTION handle_invite_acceptance() TO anon;
GRANT EXECUTE ON FUNCTION handle_invite_acceptance() TO authenticated;

-- Ensure proper sequence access
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant table access
GRANT ALL ON team_invites TO anon;
GRANT ALL ON team_invites TO authenticated;
GRANT ALL ON business_users TO anon;
GRANT ALL ON business_users TO authenticated;
GRANT ALL ON businesses TO anon;
GRANT ALL ON businesses TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION handle_invite_acceptance IS 'Handles team member invite acceptance with proper error handling and permissions';


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
  # Fix team invites access and policies

  1. Changes
    - Add policy for accessing business data through invites
    - Fix join relationship between invites and businesses
    - Grant necessary permissions

  2. Security
    - Ensure proper RLS for both tables
    - Limit access to only pending, unexpired invites
*/

-- Ensure RLS is enabled
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;

-- Add policy for accessing business data through invites
CREATE POLICY "Allow business access through invites"
    ON businesses
    FOR SELECT
    TO public
    USING (
        id IN (
            SELECT business_id 
            FROM team_invites 
            WHERE status = 'pending' AND expires_at > now()
        )
    );

-- Grant necessary permissions
GRANT SELECT ON businesses TO anon;
GRANT SELECT ON businesses TO authenticated;

-- Add helpful comment
COMMENT ON POLICY "Allow business access through invites" ON businesses IS 'Allows accessing business data for pending invites';
