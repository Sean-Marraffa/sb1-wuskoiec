/*
  # Fix Pricing Model Case
  
  1. Changes
    - Updates existing pricing model values to use lowercase
    - Ensures consistency with function queries
*/

-- Update existing pricing records to use lowercase
UPDATE billing_plans_pricing 
SET pricing_model = LOWER(pricing_model)
WHERE pricing_model IN ('Monthly', 'Yearly');

-- Re-insert seed data if missing
INSERT INTO billing_plans (name, features, is_active)
SELECT 'Standard Plan', '{"feature1": "value1"}'::jsonb, true
WHERE NOT EXISTS (
  SELECT 1 FROM billing_plans WHERE name = 'Standard Plan'
);

-- Insert pricing for the plan if missing
WITH plan_id AS (
  SELECT id FROM billing_plans WHERE name = 'Standard Plan' LIMIT 1
)
INSERT INTO billing_plans_pricing (plan_id, pricing_model, price)
SELECT 
  plan_id.id,
  pricing_model,
  price
FROM plan_id, (VALUES ('monthly', 25.00), ('yearly', 20.00)) AS v(pricing_model, price)
WHERE NOT EXISTS (
  SELECT 1 
  FROM billing_plans_pricing bpp 
  WHERE bpp.plan_id = plan_id.id 
    AND bpp.pricing_model = v.pricing_model
);