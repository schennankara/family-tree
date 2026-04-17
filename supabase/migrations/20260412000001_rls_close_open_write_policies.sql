-- =============================================================================
-- FTLS RLS Phase 1: Close open-write policies
-- Migration: 20260412000001_rls_close_open_write_policies.sql
--
-- WHY THIS EXISTS:
-- The remote schema migration (20260411035914) created narrow admin-only
-- write policies for persons/families, but ALSO created broad "Allow *"
-- policies that grant anon + authenticated unrestricted write access.
-- Because Supabase RLS policies are PERMISSIVE and OR'd together, the broad
-- policies completely nullify the narrow ones — anyone can write anything.
--
-- This migration drops the open "Allow *" policies and tightens a few others.
-- It does NOT recreate any policies — the correct narrow ones already exist.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- PERSONS
-- Drop the 3 broad open-write policies that override admin-only intent
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Allow insert persons" ON public.persons;
DROP POLICY IF EXISTS "Allow update persons" ON public.persons;
DROP POLICY IF EXISTS "Allow delete persons" ON public.persons;
-- What remains (already in schema):
--   "Admin write persons"   → INSERT, admin/super_admin only     ✓
--   "Admin update persons"  → UPDATE, admin/super_admin only     ✓
--   "Admin delete persons"  → DELETE, admin/super_admin only     ✓
--   "Editor update persons" → UPDATE, scoped via is_in_edit_scope ✓
--   "Public read persons"   → SELECT, everyone                   ✓


-- ─────────────────────────────────────────────────────────────────────────────
-- FAMILIES
-- Drop the 3 broad open-write policies
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Allow insert families" ON public.families;
DROP POLICY IF EXISTS "Allow update families" ON public.families;
DROP POLICY IF EXISTS "Allow delete families" ON public.families;
-- What remains (already in schema):
--   "Admin write families"  → INSERT, admin/super_admin only     ✓
--   "Admin update families" → UPDATE, admin/super_admin only     ✓
--   "Admin delete families" → DELETE, admin/super_admin only     ✓
--   "Public read families"  → SELECT, everyone                   ✓


-- ─────────────────────────────────────────────────────────────────────────────
-- MEDIA
-- Drop the 3 broad open-write policies
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Allow insert media" ON public.media;
DROP POLICY IF EXISTS "Allow update media" ON public.media;
DROP POLICY IF EXISTS "Allow delete media" ON public.media;
-- Add admin-only write policies for media (none existed before)
CREATE POLICY "Admin write media"
  ON public.media FOR INSERT
  TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = ANY (ARRAY['admin', 'super_admin'])
  ));
CREATE POLICY "Admin update media"
  ON public.media FOR UPDATE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = ANY (ARRAY['admin', 'super_admin'])
  ));
CREATE POLICY "Admin delete media"
  ON public.media FOR DELETE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = ANY (ARRAY['admin', 'super_admin'])
  ));
-- What remains:
--   "Admin write/update/delete media" → admin/super_admin only   ✓
--   "Public read media"               → SELECT, everyone         ✓


-- ─────────────────────────────────────────────────────────────────────────────
-- FAMILY_MEMBERS
-- Drop all open-write policies (anon and authenticated)
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Anon write family_members"   ON public.family_members;
DROP POLICY IF EXISTS "Anon update family_members"  ON public.family_members;
DROP POLICY IF EXISTS "Anon delete family_members"  ON public.family_members;
DROP POLICY IF EXISTS "Auth write family_members"   ON public.family_members;
DROP POLICY IF EXISTS "Auth update family_members"  ON public.family_members;
DROP POLICY IF EXISTS "Auth delete family_members"  ON public.family_members;
-- Add admin-only write policies
CREATE POLICY "Admin write family_members"
  ON public.family_members FOR INSERT
  TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = ANY (ARRAY['admin', 'super_admin'])
  ));
CREATE POLICY "Admin update family_members"
  ON public.family_members FOR UPDATE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = ANY (ARRAY['admin', 'super_admin'])
  ));
CREATE POLICY "Admin delete family_members"
  ON public.family_members FOR DELETE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = ANY (ARRAY['admin', 'super_admin'])
  ));
-- What remains:
--   "Admin write/update/delete family_members" → admin/super_admin only  ✓
--   "Public read family_members"               → SELECT, everyone        ✓


-- ─────────────────────────────────────────────────────────────────────────────
-- EDIT_LOG
-- Tighten read access — raw audit log should be admin-only, not public
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Public read edit_log" ON public.edit_log;
CREATE POLICY "Admin read edit_log"
  ON public.edit_log FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = ANY (ARRAY['admin', 'super_admin'])
  ));
-- NOTE: "Allow insert edit_log" (insert to public, no check) remains.
-- This is intentional — the app writes log entries for all role actions.
-- There is no UPDATE or DELETE policy, keeping the log append-only. ✓


-- ─────────────────────────────────────────────────────────────────────────────
-- USERS
-- Remove anon read — user list (emails, roles) shouldn't be public
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Anon read users" ON public.users;
-- "Authenticated read users" remains — logged-in users can see the list,
-- which the app needs for the admin panel user management view. ✓


-- ─────────────────────────────────────────────────────────────────────────────
-- VIEWER ROLE: add it to the users role check constraint
-- The existing constraint only allows: editor, admin, super_admin
-- We need to add viewer so the app's viewer role works in the DB
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE public.users
  ADD CONSTRAINT users_role_check
  CHECK (role = ANY (ARRAY[
    'viewer'::text,
    'editor'::text,
    'admin'::text,
    'super_admin'::text
  ]));
-- =============================================================================
-- SUMMARY OF NET EFFECT
-- =============================================================================
-- persons:        anon/open writes REMOVED. Admin + scoped editor writes only.
-- families:       anon/open writes REMOVED. Admin writes only.
-- media:          anon/open writes REMOVED. Admin writes only.
-- family_members: anon/open writes REMOVED. Admin writes only.
-- edit_log:       public read REMOVED. Admin read only. Insert still open.
-- users:          anon read REMOVED. Authenticated read only.
-- users role:     viewer role added to CHECK constraint.
-- =============================================================================;
