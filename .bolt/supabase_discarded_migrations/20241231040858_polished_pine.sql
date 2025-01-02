/*
  # Update Billing Plans Function
  
  1. Changes
    - Fixes ambiguous ID references by properly qualifying table names
    - Adds pricing IDs to return values
    - Maintains security and permissions
*/

-- Drop the existing function
DROP FUNCTION IF EXISTS get_billing_plans_with_pricing();

-- Recreate the function with updated return type
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
    (SELECT bpp.price FROM billing_plans_pricing bpp WHERE bpp.plan_id = bp.id AND bpp.pricing_model = 'monthly') as monthly_price,
    (SELECT bpp.price FROM billing_plans_pricing bpp WHERE bpp.plan_id = bp.id AND bpp.pricing_model = 'yearly') as yearly_price,
    (SELECT bpp.id FROM billing_plans_pricing bpp WHERE bpp.plan_id = bp.id AND bpp.pricing_model = 'monthly') as monthly_pricing_id,
    (SELECT bpp.id FROM billing_plans_pricing bpp WHERE bpp.plan_id = bp.id AND bpp.pricing_model = 'yearly') as yearly_pricing_id
  FROM billing_plans bp
  WHERE bp.is_active = true;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_billing_plans_with_pricing() TO authenticated, anon;