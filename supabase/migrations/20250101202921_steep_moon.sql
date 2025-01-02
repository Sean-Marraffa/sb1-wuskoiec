/*
  # Reservation System

  1. New Tables
    - `reservations`
      - Main reservation information
      - Status tracking
      - Pricing and discounts
    - `reservation_items`
      - Items included in reservations
      - Quantity and rate tracking
      - Subtotal calculations

  2. Functions
    - Availability checking
    - Total calculation
    - Status management

  3. Security
    - RLS policies for both tables
    - Team member access controls
*/

-- Create reservations table
CREATE TABLE reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT,
    customer_phone TEXT,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    total_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10,2),
    discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed')),
    status TEXT NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'reserved', 'in_use', 'closed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT valid_dates CHECK (end_date > start_date),
    CONSTRAINT valid_discount CHECK (
        (discount_type IS NULL AND discount_amount IS NULL) OR
        (discount_type IS NOT NULL AND discount_amount IS NOT NULL AND
         CASE 
            WHEN discount_type = 'percentage' THEN discount_amount BETWEEN 0 AND 100
            ELSE discount_amount >= 0
         END)
    )
);

-- Create reservation items table
CREATE TABLE reservation_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id UUID NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
    inventory_item_id UUID NOT NULL REFERENCES inventory_items(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    rate_type TEXT NOT NULL CHECK (
        rate_type IN ('hourly', 'daily', 'weekly', 'monthly')
    ),
    rate_amount DECIMAL(10,2) NOT NULL CHECK (rate_amount >= 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_reservations_business ON reservations(business_id);
CREATE INDEX idx_reservations_customer ON reservations(customer_id);
CREATE INDEX idx_reservations_dates ON reservations(start_date, end_date);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservation_items_reservation ON reservation_items(reservation_id);
CREATE INDEX idx_reservation_items_item ON reservation_items(inventory_item_id);

-- Enable RLS
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservation_items ENABLE ROW LEVEL SECURITY;

-- Create triggers for updated_at
CREATE TRIGGER update_reservations_updated_at
    BEFORE UPDATE ON reservations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_reservation_items_updated_at
    BEFORE UPDATE ON reservation_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Create function to calculate reservation duration
CREATE OR REPLACE FUNCTION calculate_duration(
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_rate_type TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_duration INTEGER;
BEGIN
    v_duration := CASE p_rate_type
        WHEN 'hourly' THEN 
            CEIL(EXTRACT(EPOCH FROM (p_end_date - p_start_date)) / 3600)
        WHEN 'daily' THEN 
            CEIL(EXTRACT(EPOCH FROM (p_end_date - p_start_date)) / 86400)
        WHEN 'weekly' THEN 
            CEIL(EXTRACT(EPOCH FROM (p_end_date - p_start_date)) / (86400 * 7))
        WHEN 'monthly' THEN 
            CEIL(EXTRACT(EPOCH FROM (p_end_date - p_start_date)) / (86400 * 30))
        ELSE 0
    END;
    
    RETURN v_duration;
END;
$$;

-- Create function to validate reservation
CREATE OR REPLACE FUNCTION validate_reservation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check item availability when status changes to 'reserved'
    IF (TG_OP = 'UPDATE' AND NEW.status = 'reserved' AND OLD.status != 'reserved') THEN
        -- Check each item's availability
        IF EXISTS (
            SELECT 1
            FROM reservation_items ri
            JOIN inventory_items ii ON ii.id = ri.inventory_item_id
            WHERE ri.reservation_id = NEW.id
            AND ri.quantity > ii.quantity
        ) THEN
            RAISE EXCEPTION 'One or more items exceed available quantity';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Create trigger for reservation validation
CREATE TRIGGER validate_reservation_trigger
    BEFORE INSERT OR UPDATE ON reservations
    FOR EACH ROW
    EXECUTE FUNCTION validate_reservation();

-- Create RLS policies

-- Reservations policies
CREATE POLICY "Team members can view reservations"
    ON reservations
    FOR SELECT
    USING (
        business_id IN (
            SELECT business_id 
            FROM business_users 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Account owners can manage reservations"
    ON reservations
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = reservations.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = reservations.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    );

-- Reservation items policies
CREATE POLICY "Team members can view reservation items"
    ON reservation_items
    FOR SELECT
    USING (
        reservation_id IN (
            SELECT id 
            FROM reservations 
            WHERE business_id IN (
                SELECT business_id 
                FROM business_users 
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Account owners can manage reservation items"
    ON reservation_items
    FOR ALL
    USING (
        reservation_id IN (
            SELECT id 
            FROM reservations 
            WHERE business_id IN (
                SELECT business_id 
                FROM business_users 
                WHERE user_id = auth.uid()
                AND role = 'Account Owner'
            )
        )
    )
    WITH CHECK (
        reservation_id IN (
            SELECT id 
            FROM reservations 
            WHERE business_id IN (
                SELECT business_id 
                FROM business_users 
                WHERE user_id = auth.uid()
                AND role = 'Account Owner'
            )
        )
    );

-- Grant necessary permissions
GRANT ALL ON reservations TO authenticated;
GRANT ALL ON reservation_items TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_duration TO authenticated;

-- Add helpful comments
COMMENT ON TABLE reservations IS 'Stores reservation information with status tracking';
COMMENT ON TABLE reservation_items IS 'Stores items included in each reservation';
COMMENT ON FUNCTION calculate_duration IS 'Calculates duration based on rate type';