/*
  # Add pricing scheme support

  1. Changes
    - Add pricing columns to inventory_items table:
      - hourly_rate
      - daily_rate
      - weekly_rate
      - monthly_rate
    - Remove old price column
*/

-- Add new pricing columns
ALTER TABLE inventory_items
ADD COLUMN hourly_rate decimal(10,2),
ADD COLUMN daily_rate decimal(10,2),
ADD COLUMN weekly_rate decimal(10,2),
ADD COLUMN monthly_rate decimal(10,2);

-- Drop old price column
ALTER TABLE inventory_items DROP COLUMN price;