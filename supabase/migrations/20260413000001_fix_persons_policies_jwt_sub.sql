-- =============================================================================
-- Fix persons UPDATE/DELETE policies to use auth.jwt()->>'sub' instead of auth.uid()
-- auth.uid() does not work with Supabase ECC (ES256) JWT tokens issued after
-- the automatic JWT key rotation on 2026-04-01.
-- (auth.jwt()->>'sub')::uuid extracts the user ID directly from the JWT claims
-- and works with both HS256 and ES256 tokens.
-- =============================================================================

-- Admin update persons
DROP POLICY IF EXISTS "Admin update persons" ON public.persons;
CREATE POLICY "Admin update persons"
  ON public.persons FOR UPDATE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = (auth.jwt()->>'sub')::uuid
    AND users.role = ANY (ARRAY['admin'::text, 'super_admin'::text])
  ));

-- Admin delete persons
DROP POLICY IF EXISTS "Admin delete persons" ON public.persons;
CREATE POLICY "Admin delete persons"
  ON public.persons FOR DELETE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = (auth.jwt()->>'sub')::uuid
    AND users.role = ANY (ARRAY['admin'::text, 'super_admin'::text])
  ));

-- Editor update persons
DROP POLICY IF EXISTS "Editor update persons" ON public.persons;
CREATE POLICY "Editor update persons"
  ON public.persons FOR UPDATE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = (auth.jwt()->>'sub')::uuid
    AND u.role = 'editor'::text
    AND is_in_edit_scope(u.person_id, persons.id)
  ));
