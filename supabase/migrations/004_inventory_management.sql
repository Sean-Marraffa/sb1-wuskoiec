/*
  # Inventory Management System

  1. New Tables
    - `inventory_items`
      - Core inventory item information
      - Pricing rates (hourly, daily, weekly, monthly)
      - Quantity tracking
      - Category relationship
  
  2. Security
    - Enable RLS on all tables
    - Add policies for proper access control
    - Ensure team members can view inventory
    - Restrict management to Account Owners

  3. Functions
    - Check item availability
    - Update quantity tracking
*/

-- Create inventory_items table
CREATE TABLE inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    category_id UUID REFERENCES inventory_categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    quantity INTEGER NOT NULL DEFAULT 0,
    hourly_rate DECIMAL(10,2),
    daily_rate DECIMAL(10,2),
    weekly_rate DECIMAL(10,2),
    monthly_rate DECIMAL(10,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT quantity_non_negative CHECK (quantity >= 0)
);

-- Create indexes
CREATE INDEX idx_inventory_items_business ON inventory_items(business_id);
CREATE INDEX idx_inventory_items_category ON inventory_items(category_id);

-- Enable RLS
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER update_inventory_items_updated_at
    BEFORE UPDATE ON inventory_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Create function to check item availability
CREATE OR REPLACE FUNCTION check_item_availability(
    p_item_id UUID,
    p_quantity INTEGER,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_available_quantity INTEGER;
    v_total_quantity INTEGER;
    v_reserved_quantity INTEGER;
BEGIN
    -- Get total inventory quantity
    SELECT quantity INTO v_total_quantity
    FROM inventory_items
    WHERE id = p_item_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'available', false,
            'error', 'Item not found'
        );
    END IF;

    -- Calculate reserved quantity for the date range
    SELECT COALESCE(SUM(ri.quantity), 0) INTO v_reserved_quantity
    FROM reservation_items ri
    JOIN reservations r ON r.id = ri.reservation_id
    WHERE ri.inventory_item_id = p_item_id
    AND r.status = 'reserved'
    AND r.end_date >= p_start_date
    AND r.start_date <= p_end_date;

    v_available_quantity := v_total_quantity - v_reserved_quantity;

    RETURN jsonb_build_object(
        'available', v_available_quantity >= p_quantity,
        'available_quantity', v_available_quantity,
        'total_quantity', v_total_quantity,
        'reserved_quantity', v_reserved_quantity
    );
END;
$$;

-- Create RLS Policies

-- View policy for team members
CREATE POLICY "Team members can view inventory"
    ON inventory_items
    FOR SELECT
    USING (
        business_id IN (
            SELECT business_id 
            FROM business_users 
            WHERE user_id = auth.uid()
        )
    );

-- Full access policy for account owners
CREATE POLICY "Account owners can manage inventory"
    ON inventory_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = inventory_items.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = inventory_items.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    );

-- Grant necessary permissions
GRANT ALL ON inventory_items TO authenticated;
GRANT EXECUTE ON FUNCTION check_item_availability TO authenticated;

-- Add helpful comments
COMMENT ON TABLE inventory_items IS 'Stores inventory items with pricing and availability information';
COMMENT ON FUNCTION check_item_availability IS 'Checks if an item is available for a given quantity and date range';