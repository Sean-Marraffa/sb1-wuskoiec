/*
  # Fix cascade deletion for business profiles

  1. Changes
    - Add ON DELETE CASCADE to all foreign key constraints referencing business_profiles
    - Add ON DELETE CASCADE to all foreign key constraints referencing customers
    - Add ON DELETE CASCADE to all foreign key constraints referencing inventory_items
    
  2. Tables Modified
    - user_roles
    - inventory_items
    - inventory_categories
    - customers
    - reservations
    - reservation_items
    - reservation_status_settings
*/

-- Drop existing foreign key constraints
ALTER TABLE user_roles
DROP CONSTRAINT IF EXISTS user_roles_business_id_fkey;

ALTER TABLE inventory_items
DROP CONSTRAINT IF EXISTS inventory_items_business_id_fkey;

ALTER TABLE inventory_categories
DROP CONSTRAINT IF EXISTS inventory_categories_business_id_fkey;

ALTER TABLE customers
DROP CONSTRAINT IF EXISTS customers_business_id_fkey;

ALTER TABLE reservations
DROP CONSTRAINT IF EXISTS reservations_business_id_fkey;

ALTER TABLE reservation_status_settings
DROP CONSTRAINT IF EXISTS reservation_status_settings_business_id_fkey;

-- Recreate constraints with CASCADE
ALTER TABLE user_roles
ADD CONSTRAINT user_roles_business_id_fkey
FOREIGN KEY (business_id)
REFERENCES business_profiles(id)
ON DELETE CASCADE;

ALTER TABLE inventory_items
ADD CONSTRAINT inventory_items_business_id_fkey
FOREIGN KEY (business_id)
REFERENCES business_profiles(id)
ON DELETE CASCADE;

ALTER TABLE inventory_categories
ADD CONSTRAINT inventory_categories_business_id_fkey
FOREIGN KEY (business_id)
REFERENCES business_profiles(id)
ON DELETE CASCADE;

ALTER TABLE customers
ADD CONSTRAINT customers_business_id_fkey
FOREIGN KEY (business_id)
REFERENCES business_profiles(id)
ON DELETE CASCADE;

ALTER TABLE reservations
ADD CONSTRAINT reservations_business_id_fkey
FOREIGN KEY (business_id)
REFERENCES business_profiles(id)
ON DELETE CASCADE;

ALTER TABLE reservation_status_settings
ADD CONSTRAINT reservation_status_settings_business_id_fkey
FOREIGN KEY (business_id)
REFERENCES business_profiles(id)
ON DELETE CASCADE;