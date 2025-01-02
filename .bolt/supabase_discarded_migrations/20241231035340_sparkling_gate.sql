/*
  # Add Billing Plans Function
  
  1. New Functions
    - `get_billing_plans_with_pricing()`: Returns active billing plans with their pricing options
  
  2. Changes
    - Creates a function to fetch billing plans and their pricing in a single query
    - Returns structured JSON with plan details and pricing options
*/

CREATE OR REPLACE FUNCTION get_billing_plans_with_pricing()
RETURNS TABLE (
  id uuid,
  name text,
  features jsonb,
  is_active boolean,
  monthly_price numeric,
  yearly_price numeric
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
    (SELECT price FROM billing_plans_pricing WHERE plan_id = bp.id AND pricing_model = 'Monthly') as monthly_price,
    (SELECT price FROM billing_plans_pricing WHERE plan_id = bp.id AND pricing_model = 'Yearly') as yearly_price
  FROM billing_plans bp
  WHERE bp.is_active = true;
END;
$$;