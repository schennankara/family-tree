-- =============================================================================
-- Update is_in_edit_scope function to match frontend canEditorDirectEdit logic
-- Previous version only checked: self, siblings, descendants
-- New version checks: self, spouse, descendants, spouse's descendants,
-- parents, siblings + spouses + descendants,
-- parents-in-law, siblings-in-law + spouses + full descendants
-- =============================================================================

CREATE OR REPLACE FUNCTION public.is_in_edit_scope(editor_person_id text, target_person_id text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  desc_check BOOLEAN;
  spouse_id TEXT;
  parent_fam RECORD;
  sib_id TEXT;
  sib_spouse_id TEXT;
  sp_parent_fam RECORD;
  sil_id TEXT;
BEGIN
  -- Can always edit self
  IF editor_person_id = target_person_id THEN RETURN TRUE; END IF;

  -- My spouse
  SELECT CASE WHEN f.husband_id = editor_person_id THEN f.wife_id ELSE f.husband_id END
  INTO spouse_id
  FROM families f
  WHERE f.husband_id = editor_person_id OR f.wife_id = editor_person_id
  LIMIT 1;

  IF spouse_id IS NOT NULL AND spouse_id = target_person_id THEN RETURN TRUE; END IF;

  -- My descendants
  WITH RECURSIVE descendants AS (
    SELECT unnest(f.children) AS pid
    FROM families f
    WHERE f.husband_id = editor_person_id OR f.wife_id = editor_person_id
    UNION
    SELECT unnest(f2.children) AS pid
    FROM families f2
    JOIN descendants d ON f2.husband_id = d.pid OR f2.wife_id = d.pid
  )
  SELECT EXISTS (SELECT 1 FROM descendants WHERE pid = target_person_id) INTO desc_check;
  IF COALESCE(desc_check, FALSE) THEN RETURN TRUE; END IF;

  -- Spouse's descendants
  IF spouse_id IS NOT NULL THEN
    WITH RECURSIVE sp_descendants AS (
      SELECT unnest(f.children) AS pid
      FROM families f
      WHERE f.husband_id = spouse_id OR f.wife_id = spouse_id
      UNION
      SELECT unnest(f2.children) AS pid
      FROM families f2
      JOIN sp_descendants d ON f2.husband_id = d.pid OR f2.wife_id = d.pid
    )
    SELECT EXISTS (SELECT 1 FROM sp_descendants WHERE pid = target_person_id) INTO desc_check;
    IF COALESCE(desc_check, FALSE) THEN RETURN TRUE; END IF;
  END IF;

  -- My parents + siblings + siblings' spouses + siblings' full descendants
  SELECT f.* INTO parent_fam
  FROM families f
  WHERE editor_person_id = ANY(f.children::text[])
  LIMIT 1;

  IF parent_fam IS NOT NULL THEN
    IF parent_fam.husband_id = target_person_id OR parent_fam.wife_id = target_person_id THEN RETURN TRUE; END IF;
    FOR sib_id IN SELECT unnest(parent_fam.children::text[]) LOOP
      IF sib_id = target_person_id THEN RETURN TRUE; END IF;
      SELECT CASE WHEN f.husband_id = sib_id THEN f.wife_id ELSE f.husband_id END
      INTO sib_spouse_id
      FROM families f
      WHERE f.husband_id = sib_id OR f.wife_id = sib_id LIMIT 1;
      IF sib_spouse_id IS NOT NULL AND sib_spouse_id = target_person_id THEN RETURN TRUE; END IF;
      WITH RECURSIVE sib_desc AS (
        SELECT unnest(f.children) AS pid
        FROM families f WHERE f.husband_id = sib_id OR f.wife_id = sib_id
        UNION
        SELECT unnest(f2.children) AS pid
        FROM families f2 JOIN sib_desc d ON f2.husband_id = d.pid OR f2.wife_id = d.pid
      )
      SELECT EXISTS (SELECT 1 FROM sib_desc WHERE pid = target_person_id) INTO desc_check;
      IF COALESCE(desc_check, FALSE) THEN RETURN TRUE; END IF;
    END LOOP;
  END IF;

  -- Parents-in-law + siblings-in-law + their spouses + their full descendants
  IF spouse_id IS NOT NULL THEN
    SELECT f.* INTO sp_parent_fam
    FROM families f
    WHERE spouse_id = ANY(f.children::text[])
    LIMIT 1;

    IF sp_parent_fam IS NOT NULL THEN
      IF sp_parent_fam.husband_id = target_person_id OR sp_parent_fam.wife_id = target_person_id THEN RETURN TRUE; END IF;
      FOR sil_id IN SELECT unnest(sp_parent_fam.children::text[]) LOOP
        IF sil_id = target_person_id THEN RETURN TRUE; END IF;
        SELECT CASE WHEN f.husband_id = sil_id THEN f.wife_id ELSE f.husband_id END
        INTO sib_spouse_id
        FROM families f
        WHERE f.husband_id = sil_id OR f.wife_id = sil_id LIMIT 1;
        IF sib_spouse_id IS NOT NULL AND sib_spouse_id = target_person_id THEN RETURN TRUE; END IF;
        WITH RECURSIVE sil_desc AS (
          SELECT unnest(f.children) AS pid
          FROM families f WHERE f.husband_id = sil_id OR f.wife_id = sil_id
          UNION
          SELECT unnest(f2.children) AS pid
          FROM families f2 JOIN sil_desc d ON f2.husband_id = d.pid OR f2.wife_id = d.pid
        )
        SELECT EXISTS (SELECT 1 FROM sil_desc WHERE pid = target_person_id) INTO desc_check;
        IF COALESCE(desc_check, FALSE) THEN RETURN TRUE; END IF;
      END LOOP;
    END IF;
  END IF;

  RETURN FALSE;
END;
$$;
