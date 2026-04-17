
ALTER TABLE families ADD COLUMN IF NOT EXISTS divorced boolean DEFAULT false;
ALTER TABLE families ADD COLUMN IF NOT EXISTS divorce_date text DEFAULT '';
;
