-- Preserve intentional live-only database behavior in migration history.
-- This does not include backup_apr15, which is operational backup data rather
-- than part of the application schema.

-- Keep the looser INSERT policy currently present in the live database.
DROP POLICY IF EXISTS "Admin write persons" ON public.persons;
CREATE POLICY "Admin write persons"
  ON public.persons FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Keep the live debug helper currently present in the database.
CREATE OR REPLACE FUNCTION public.test_auth_uid()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT auth.uid();
$function$;

GRANT ALL ON FUNCTION public.test_auth_uid() TO anon;
GRANT ALL ON FUNCTION public.test_auth_uid() TO authenticated;
GRANT ALL ON FUNCTION public.test_auth_uid() TO service_role;
