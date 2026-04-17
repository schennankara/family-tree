
-- Add _extra_gedcom column to persons table (stores unmanaged GEDCOM lines per person)
ALTER TABLE persons ADD COLUMN IF NOT EXISTS _extra_gedcom text DEFAULT '';

-- Add _extra_gedcom column to families table (stores unmanaged GEDCOM lines per family)  
ALTER TABLE families ADD COLUMN IF NOT EXISTS _extra_gedcom text DEFAULT '';

-- Add title_prefix column to persons table (Dr, Pastor, etc.)
ALTER TABLE persons ADD COLUMN IF NOT EXISTS title_prefix text DEFAULT '';

-- Add burial_date column to persons table
ALTER TABLE persons ADD COLUMN IF NOT EXISTS burial_date text DEFAULT '';

-- Create a table for top-level GEDCOM records (OBJE, NOTE, source templates, etc.)
CREATE TABLE IF NOT EXISTS gedcom_meta (
  id text PRIMARY KEY,
  record_type text NOT NULL,
  raw_gedcom text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on gedcom_meta
ALTER TABLE gedcom_meta ENABLE ROW LEVEL SECURITY;

-- RLS policies for gedcom_meta
DO $$ BEGIN
  CREATE POLICY "Allow anonymous read" ON gedcom_meta FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Allow anonymous insert" ON gedcom_meta FOR INSERT WITH CHECK (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Allow anonymous update" ON gedcom_meta FOR UPDATE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Allow anonymous delete" ON gedcom_meta FOR DELETE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
;
