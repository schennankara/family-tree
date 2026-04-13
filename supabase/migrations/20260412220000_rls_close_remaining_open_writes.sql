-- =============================================================================
-- FTLS RLS: Close remaining open write policies
-- Migration: 20260412220000_rls_close_remaining_open_writes.sql
--
-- Current state on production after troubleshooting session:
--   persons:   Allow insert/update/delete still open  ← needs closing
--   families:  Allow insert/update/delete still open  ← needs closing
--   edit_log:  Public read still open                 ← needs tightening
--   media:     Already clean ✓
--   family_members: Already clean ✓
--   users:     Already clean ✓
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- PERSONS: drop the 3 open policies
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Allow insert persons" ON public.persons;
DROP POLICY IF EXISTS "Allow update persons" ON public.persons;
DROP POLICY IF EXISTS "Allow delete persons" ON public.persons;

-- ─────────────────────────────────────────────────────────────────────────────
-- FAMILIES: drop the 3 open policies
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Allow insert families" ON public.families;
DROP POLICY IF EXISTS "Allow update families" ON public.families;
DROP POLICY IF EXISTS "Allow delete families" ON public.families;

-- ─────────────────────────────────────────────────────────────────────────────
-- EDIT_LOG: restrict read to admins only
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Public read edit_log" ON public.edit_log;
DROP POLICY IF EXISTS "Admin read edit_log" ON public.edit_log;

CREATE POLICY "Admin read edit_log"
  ON public.edit_log FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = ANY (ARRAY['admin'::text, 'super_admin'::text])
  ));

-- =============================================================================
-- RESULT after this migration:
--   persons:        SELECT public | INSERT/UPDATE/DELETE admin+editor only ✓
--   families:       SELECT public | INSERT/UPDATE/DELETE admin only ✓
--   edit_log:       SELECT admin only | INSERT open (needed for logging) ✓
--   media:          SELECT public | INSERT/UPDATE/DELETE admin only ✓
--   family_members: SELECT public | INSERT/UPDATE/DELETE admin only ✓
--   users:          SELECT authenticated | INSERT/UPDATE/DELETE super_admin ✓
-- =============================================================================
