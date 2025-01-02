/*
  # Customer Management System

  1. New Tables
    - `customers`
      - `id` (uuid, primary key)
      - `business_id` (uuid, foreign key to businesses)
      - `name` (text, required)
      - `email` (text, optional)
      - `phone` (text, optional)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `customers` table
    - Add policies for team member access
    - Add policies for account owner management
*/

-- Create customers table
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT customers_email_format CHECK (
        email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
);

-- Create indexes
CREATE INDEX idx_customers_business ON customers(business_id);
CREATE INDEX idx_customers_email ON customers(email) WHERE email IS NOT NULL;
CREATE INDEX idx_customers_name ON customers(name text_pattern_ops);

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Create RLS Policies

-- View policy for team members
CREATE POLICY "Team members can view customers"
    ON customers
    FOR SELECT
    USING (
        business_id IN (
            SELECT business_id 
            FROM business_users 
            WHERE user_id = auth.uid()
        )
    );

-- Full access policy for account owners
CREATE POLICY "Account owners can manage customers"
    ON customers
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = customers.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM business_users 
            WHERE business_id = customers.business_id
            AND user_id = auth.uid()
            AND role = 'Account Owner'
        )
    );

-- Grant necessary permissions
GRANT ALL ON customers TO authenticated;

-- Add helpful comments
COMMENT ON TABLE customers IS 'Stores customer information for each business';
COMMENT ON COLUMN customers.email IS 'Optional email address with format validation';
COMMENT ON COLUMN customers.phone IS 'Optional phone number';