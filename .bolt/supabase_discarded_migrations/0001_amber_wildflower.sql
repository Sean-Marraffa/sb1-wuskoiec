-- Master Migration File

-- Tables Migration Section

CREATE TABLE billing_plans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    features JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE billing_plans_pricing (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    plan_id UUID NOT NULL REFERENCES billing_plans(id) ON DELETE CASCADE,
    pricing_model TEXT NOT NULL, -- 'monthly' or 'yearly'
    price NUMERIC NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE business_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID,
    business_id UUID,
    role TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE business_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    business_id UUID,
    plan_id UUID,
    pricing_id UUID,
    status TEXT,
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE businesses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT,
    type TEXT,
    contact_email TEXT,
    street_address_1 TEXT,
    street_address_2 TEXT,
    city TEXT,
    state_province TEXT,
    postal_code TEXT,
    country TEXT,
    status TEXT DEFAULT 'pending_setup'::TEXT,
    status_updated_at TIMESTAMP DEFAULT now(),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Enable Row-Level Security (RLS) for all tables

ALTER TABLE billing_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_plans_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;

-- Function and Trigger Section

CREATE OR REPLACE FUNCTION create_pending_business()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
  business_id uuid;
BEGIN
  IF (NEW.raw_user_meta_data->>'needs_business_profile')::boolean = true THEN
    -- Create pending business profile
    INSERT INTO businesses (
      name,
      type,
      contact_email,
      status,
      status_updated_at
    ) VALUES (
      'Pending Setup',
      'Pending',
      NEW.email,
      'pending_setup',
      now()
    ) RETURNING id INTO business_id;

    -- Create business user association with Account Owner role
    INSERT INTO business_users (
      user_id,
      business_id,
      role,
      is_default
    ) VALUES (
      NEW.id,
      business_id,
      'Account Owner',
      true
    );

    -- Update user metadata with pending business ID
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_set(
      COALESCE(raw_user_meta_data, '{}'::jsonb),
      '{pending_business_id}',
      to_jsonb(business_id::text)
    )
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION get_billing_plans_with_pricing()
RETURNS TABLE (
  id uuid,
  name text,
  features jsonb,
  is_active boolean,
  monthly_price numeric,
  yearly_price numeric,
  monthly_pricing_id uuid,
  yearly_pricing_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    bp.id,
    bp.name,
    bp.features,
    bp.is_active,
    monthly.price as monthly_price,
    yearly.price as yearly_price,
    monthly.id as monthly_pricing_id,
    yearly.id as yearly_pricing_id
  FROM billing_plans bp
  LEFT JOIN billing_plans_pricing monthly 
    ON monthly.plan_id = bp.id 
    AND monthly.pricing_model = 'monthly'
  LEFT JOIN billing_plans_pricing yearly 
    ON yearly.plan_id = bp.id 
    AND yearly.pricing_model = 'yearly'
  WHERE bp.is_active = true;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_billing_plans_with_pricing() TO authenticated, anon;

-- Create the trigger
CREATE TRIGGER on_auth_user_created_pending_business
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_pending_business();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_pending_business TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION create_pending_business IS 'Creates pending business profile and associates the user as Account Owner when a new user signs up with needs_business_profile flag.';

CREATE OR REPLACE FUNCTION check_user_role(
    target_business_id UUID,
    required_role TEXT,
    authenticated_user_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    has_role BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM business_users bu
        WHERE bu.business_id = target_business_id
          AND bu.user_id = authenticated_user_id
          AND bu.role = required_role
    ) INTO has_role;

    RETURN has_role;
END;
$$;

-- Add helpful comment
COMMENT ON FUNCTION check_user_role IS 'Checks if an authenticated user has a specific role for a target business.';

CREATE OR REPLACE FUNCTION get_default_business()
RETURNS TABLE (
    business_id UUID,
    business_name TEXT,
    role TEXT
) LANGUAGE plpgsql
AS $$
BEGIN
    -- Try to get explicitly set default
    RETURN QUERY
    SELECT
        bu.business_id,
        b.name AS business_name,
        bu.role
    FROM business_users bu
    JOIN businesses b ON b.id = bu.business_id
    WHERE bu.user_id = auth.uid()
      AND bu.is_default = true
    LIMIT 1;

    -- If no rows returned, get first business
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT
            bu.business_id,
            b.name AS business_name,
            bu.role
        FROM business_users bu
        JOIN businesses b ON b.id = bu.business_id
        WHERE bu.user_id = auth.uid()
        LIMIT 1;
    END IF;
END;
$$;

-- Policy Section

CREATE POLICY "allow_business_profile_updates"
ON "public"."businesses"
FOR ALL
TO authenticated
USING (
    check_user_role(id, 'Account Owner'::TEXT, auth.uid())
)
WITH CHECK (
    check_user_role(id, 'Account Owner'::TEXT, auth.uid())
);

CREATE POLICY "allow_business_subscriptions_insert"
ON "public"."business_subscriptions"
FOR INSERT
TO authenticated
WITH CHECK (
    business_id IN (
        SELECT business_users.business_id
        FROM business_users
        WHERE (
            business_users.user_id = auth.uid()
            AND business_users.role = 'Account Owner'::TEXT
        )
    )
);

CREATE POLICY "allow_authenticated_read_business_users"
ON "public"."business_users"
FOR SELECT
TO authenticated
USING (
    true
);

CREATE POLICY "allow_read_billing_plans"
ON "public"."billing_plans"
FOR SELECT
TO authenticated, anon
USING (
    true
);

CREATE POLICY "allow_read_plan_pricing"
ON "public"."billing_plans_pricing"
FOR SELECT
TO authenticated, anon
USING (
    true
);

CREATE POLICY "allow_business_user_insert"
ON "public"."business_users"
FOR INSERT
TO authenticated
WITH CHECK (
    true
);

CREATE POLICY "allow_business_users_update"
ON "public"."business_users"
FOR UPDATE
TO authenticated
USING (
    check_user_role(business_id, 'Account Owner'::TEXT, auth.uid())
)
WITH CHECK (
    check_user_role(business_id, 'Account Owner'::TEXT, auth.uid())
);

-- Seed Data for Billing Plans

-- Insert into billing_plans
INSERT INTO billing_plans (name, features, is_active)
VALUES
    ('Standard Plan', '{"feature1": "value1"}'::jsonb, true)

-- Insert into billing_plans_pricing
INSERT INTO billing_plans_pricing (plan_id, pricing_model, price)
VALUES
    ((SELECT id FROM billing_plans WHERE name = 'Standard Plan'), 'monthly', 25.00),
    ((SELECT id FROM billing_plans WHERE name = 'Standard Plan'), 'yearly', 20.00);
