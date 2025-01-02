/*
  # Optimize Billing Plans Function
  
  1. Changes
    - Replaces subqueries with LEFT JOINs for better performance
    - Adds explicit table aliases for clarity
    - Maintains same return structure
*/

-- Drop the existing function
DROP FUNCTION IF EXISTS get_billing_plans_with_pricing();

-- Recreate the function with optimized query
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