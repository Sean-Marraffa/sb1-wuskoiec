/*
  # Fix cascade deletion for reservation items

  1. Changes
    - Add ON DELETE CASCADE to reservation_items.inventory_item_id foreign key
    
  2. Tables Modified
    - reservation_items
*/

-- Drop existing foreign key constraint
ALTER TABLE reservation_items
DROP CONSTRAINT IF EXISTS reservation_items_inventory_item_id_fkey;

-- Recreate constraint with CASCADE
ALTER TABLE reservation_items
ADD CONSTRAINT reservation_items_inventory_item_id_fkey
FOREIGN KEY (inventory_item_id)
REFERENCES inventory_items(id)
ON DELETE CASCADE;