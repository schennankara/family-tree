-- =============================================================================
-- Fix edit_log INSERT policy to allow authenticated users
-- The previous policy only allowed anon (public) role, blocking editors/admins
-- =============================================================================

DROP POLICY IF EXISTS "Allow insert edit_log" ON public.edit_log;
CREATE POLICY "Allow insert edit_log"
  ON public.edit_log FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);
