/*
  # Add billing tables

  1. New Tables
    - `billing_plans`
      - Stores available subscription plans
      - Fields: id, name, price, interval, features, created_at
    
    - `business_subscriptions`
      - Tracks business subscriptions
      - Fields: id, business_id, plan_id, status, current_period_start, current_period_end, created_at
      - Links businesses to their selected plans
      - Includes subscription status and period tracking

  2. Security
    - Enable RLS on both tables
    - Add policies for super admin access
    - Add policies for business owners to view their subscriptions
*/

-- Create billing_plans table
CREATE TABLE billing_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  price decimal(10,2) NOT NULL,
  interval text NOT NULL CHECK (interval IN ('monthly', 'yearly')),
  features jsonb NOT NULL DEFAULT '[]',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create business_subscriptions table
CREATE TABLE business_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES business_profiles(id) ON DELETE CASCADE NOT NULL,
  plan_id uuid REFERENCES billing_plans(id) NOT NULL,
  status text NOT NULL CHECK (status IN ('active', 'canceled', 'past_due')),
  current_period_start timestamptz NOT NULL,
  current_period_end timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(business_id)  -- One active subscription per business
);

-- Enable RLS
ALTER TABLE billing_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_subscriptions ENABLE ROW LEVEL SECURITY;

-- Update triggers
CREATE TRIGGER update_billing_plans_updated_at
  BEFORE UPDATE ON billing_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_inventory_updated_at();

CREATE TRIGGER update_business_subscriptions_updated_at
  BEFORE UPDATE ON business_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_inventory_updated_at();

-- Policies for billing_plans
CREATE POLICY "billing_plans_super_admin_all"
  ON billing_plans
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "billing_plans_read_all"
  ON billing_plans
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Policies for business_subscriptions
CREATE POLICY "business_subscriptions_super_admin_all"
  ON business_subscriptions
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "business_subscriptions_read_own"
  ON business_subscriptions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = business_subscriptions.business_id
      AND user_roles.user_id = auth.uid()
    )
  );

-- Insert default plans
INSERT INTO billing_plans (name, price, interval, features) VALUES
  ('Monthly Plan', 25.00, 'monthly', '["All features included", "Priority support", "Advanced analytics", "Cancel anytime"]'),
  ('Yearly Plan', 20.00, 'yearly', '["All features included", "Priority support", "Advanced analytics", "Cancel anytime", "Bulk discounts", "Premium integrations"]');