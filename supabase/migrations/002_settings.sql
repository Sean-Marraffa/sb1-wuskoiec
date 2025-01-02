/*
  # Settings: Inventory Categories and Reservation Status Settings

  ## Tables
    - inventory_categories: Stores categories of inventory items
    - reservation_status_settings: Stores reservation status configurations

  ## Functions
    - update_updated_at: Updates the `updated_at` field for tracking changes

  ## Security
    - RLS enabled on all tables
    - Policies for business owners and team members

  ## Changes
    - Added btree index on `business_id` for performance
    - Added `updated_at` triggers for both tables
*/

-- Create the inventory categories table
CREATE TABLE IF NOT EXISTS public.inventory_categories (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT inventory_categories_pkey PRIMARY KEY (id),
    CONSTRAINT inventory_categories_business_id_fkey FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

-- Create the reservation status settings table
CREATE TABLE IF NOT EXISTS public.reservation_status_settings (
    business_id uuid NOT NULL,
    status_key text NOT NULL,
    label text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT reservation_status_settings_pkey PRIMARY KEY (business_id, status_key),
    CONSTRAINT reservation_status_settings_business_id_fkey FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

-- Create index for business_id lookups in inventory_categories
CREATE INDEX IF NOT EXISTS idx_categories_business 
    ON public.inventory_categories USING btree (business_id);

-- Create trigger function for updating updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updating updated_at
CREATE TRIGGER update_inventory_categories_updated_at
    BEFORE UPDATE ON inventory_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_reservation_status_settings_updated_at
    BEFORE UPDATE ON reservation_status_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Enable Row Level Security on both tables
ALTER TABLE inventory_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservation_status_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for inventory_categories
CREATE POLICY "Users can view their business categories"
    ON inventory_categories
    FOR SELECT
    USING (
        business_id IN (
            SELECT business_id 
            FROM business_users 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Business owners can manage categories"
    ON inventory_categories
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = inventory_categories.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = inventory_categories.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    );

-- Create RLS policies for reservation_status_settings
CREATE POLICY "Users can view their business status settings"
    ON reservation_status_settings
    FOR SELECT
    USING (
        business_id IN (
            SELECT business_id 
            FROM business_users 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Account owners can manage status settings"
    ON reservation_status_settings
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = reservation_status_settings.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = reservation_status_settings.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    );

-- Grant necessary permissions for both tables
GRANT ALL ON inventory_categories TO authenticated;
GRANT ALL ON inventory_categories TO service_role;
GRANT ALL ON reservation_status_settings TO authenticated;
GRANT ALL ON reservation_status_settings TO service_role;
