/*
  # Reservation Lookup Functions

  1. Customer Lookup
    - Search customers by name/email
    - Get customer details with business isolation

  2. Inventory Lookup
    - Search available items
    - Check availability for date range
    - Get rates and details

  3. Security
    - Business isolation
    - Team member access controls
*/

-- Create customer search function
CREATE OR REPLACE FUNCTION search_customers(
    p_business_id UUID,
    p_search_term TEXT
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    email TEXT,
    phone TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Verify caller has access to business
    IF NOT EXISTS (
        SELECT 1 
        FROM business_users 
        WHERE business_id = p_business_id 
        AND user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Not authorized to search customers for this business';
    END IF;

    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.email,
        c.phone
    FROM customers c
    WHERE c.business_id = p_business_id
    AND (
        c.name ILIKE '%' || p_search_term || '%'
        OR c.email ILIKE '%' || p_search_term || '%'
        OR c.phone ILIKE '%' || p_search_term || '%'
    )
    ORDER BY 
        CASE 
            WHEN c.name ILIKE p_search_term || '%' THEN 0
            WHEN c.name ILIKE '%' || p_search_term || '%' THEN 1
            ELSE 2
        END,
        c.name
    LIMIT 10;
END;
$$;

-- Create function to get available inventory items
CREATE OR REPLACE FUNCTION get_available_items(
    p_business_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_search_term TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    category_name TEXT,
    total_quantity INTEGER,
    available_quantity INTEGER,
    hourly_rate DECIMAL,
    daily_rate DECIMAL,
    weekly_rate DECIMAL,
    monthly_rate DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Verify caller has access to business
    IF NOT EXISTS (
        SELECT 1 
        FROM business_users 
        WHERE business_id = p_business_id 
        AND user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Not authorized to view inventory for this business';
    END IF;

    RETURN QUERY
    WITH reserved_quantities AS (
        SELECT 
            ri.inventory_item_id,
            COALESCE(SUM(ri.quantity), 0) as reserved_qty
        FROM reservations r
        JOIN reservation_items ri ON ri.reservation_id = r.id
        WHERE r.business_id = p_business_id
        AND r.status = 'reserved'
        AND r.end_date >= p_start_date
        AND r.start_date <= p_end_date
        GROUP BY ri.inventory_item_id
    )
    SELECT 
        i.id,
        i.name,
        i.description,
        ic.name as category_name,
        i.quantity as total_quantity,
        i.quantity - COALESCE(rq.reserved_qty, 0) as available_quantity,
        i.hourly_rate,
        i.daily_rate,
        i.weekly_rate,
        i.monthly_rate
    FROM inventory_items i
    LEFT JOIN inventory_categories ic ON ic.id = i.category_id
    LEFT JOIN reserved_quantities rq ON rq.inventory_item_id = i.id
    WHERE i.business_id = p_business_id
    AND i.quantity > 0
    AND (
        p_search_term IS NULL
        OR i.name ILIKE '%' || p_search_term || '%'
        OR i.description ILIKE '%' || p_search_term || '%'
        OR ic.name ILIKE '%' || p_search_term || '%'
    )
    AND (i.quantity - COALESCE(rq.reserved_qty, 0)) > 0
    ORDER BY 
        CASE 
            WHEN i.name ILIKE p_search_term || '%' THEN 0
            WHEN i.name ILIKE '%' || p_search_term || '%' THEN 1
            ELSE 2
        END,
        i.name
    LIMIT 20;
END;
$$;

-- Create function to get item details with rates
CREATE OR REPLACE FUNCTION get_item_details(
    p_item_id UUID,
    p_business_id UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    category_name TEXT,
    quantity INTEGER,
    hourly_rate DECIMAL,
    daily_rate DECIMAL,
    weekly_rate DECIMAL,
    monthly_rate DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Verify caller has access to business
    IF NOT EXISTS (
        SELECT 1 
        FROM business_users 
        WHERE business_id = p_business_id 
        AND user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Not authorized to view item details for this business';
    END IF;

    RETURN QUERY
    SELECT 
        i.id,
        i.name,
        i.description,
        ic.name as category_name,
        i.quantity,
        i.hourly_rate,
        i.daily_rate,
        i.weekly_rate,
        i.monthly_rate
    FROM inventory_items i
    LEFT JOIN inventory_categories ic ON ic.id = i.category_id
    WHERE i.id = p_item_id
    AND i.business_id = p_business_id;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION search_customers TO authenticated;
GRANT EXECUTE ON FUNCTION get_available_items TO authenticated;
GRANT EXECUTE ON FUNCTION get_item_details TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION search_customers IS 'Search customers with business isolation and proper access control';
COMMENT ON FUNCTION get_available_items IS 'Get available inventory items with quantities and rates for date range';
COMMENT ON FUNCTION get_item_details IS 'Get detailed item information with rates';