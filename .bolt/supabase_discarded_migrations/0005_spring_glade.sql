/*
  # Create Example Function
  
  1. Changes
    - Creates a new function that calculates total revenue for a business
    - Includes proper security and permissions
    - Uses row level security
  
  2. Notes
    - Function is SECURITY DEFINER to bypass RLS
    - Includes proper error handling
    - Returns aggregated data safely
*/

-- Create the function
CREATE OR REPLACE FUNCTION calculate_business_revenue(
  business_id uuid,
  start_date date DEFAULT NULL,
  end_date date DEFAULT NULL
)
RETURNS TABLE (
  total_revenue numeric,
  period_start date,
  period_end date
)
LANGUAGE plpgsql
SECURITY DEFINER  -- Runs with creator's permissions
SET search_path = public  -- Prevent search_path injection
AS $$
DECLARE
  actual_start date;
  actual_end date;
BEGIN
  -- Verify user has access to this business
  IF NOT EXISTS (
    SELECT 1 
    FROM business_users 
    WHERE business_id = $1 
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Set date range
  actual_start := COALESCE(start_date, CURRENT_DATE - INTERVAL '30 days');
  actual_end := COALESCE(end_date, CURRENT_DATE);

  -- Calculate and return revenue
  RETURN QUERY
  SELECT 
    COALESCE(SUM(total_price), 0) as total_revenue,
    actual_start as period_start,
    actual_end as period_end
  FROM reservations
  WHERE business_id = $1
  AND created_at::date BETWEEN actual_start AND actual_end;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION calculate_business_revenue TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION calculate_business_revenue IS 'Calculates total revenue for a business within a date range';