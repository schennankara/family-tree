-- =============================================================================
-- FTLS RLS Cleanup: Remove test policy, reconcile migration history
-- Migration: 20260412230000_rls_cleanup_test_policy.sql
--
-- This removes the "Test authenticated insert" policy left over from
-- debugging the ECC JWT / auth.uid() issue on 2026-04-12.
-- All other policies are already correct per audit.
-- =============================================================================

DROP POLICY IF EXISTS "Test authenticated insert" ON public.persons;

-- Verify final state (informational comment):
-- persons:        SELECT public | INSERT/UPDATE/DELETE admin+editor only ✓
-- families:       SELECT public | INSERT/UPDATE/DELETE admin only ✓
-- edit_log:       SELECT admin only | INSERT open ✓
-- media:          SELECT public | INSERT/UPDATE/DELETE admin only ✓
-- family_members: SELECT public | INSERT/UPDATE/DELETE admin only ✓
-- users:          SELECT authenticated | INSERT/UPDATE/DELETE super_admin ✓
