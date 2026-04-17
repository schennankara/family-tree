DROP POLICY IF EXISTS "Admin write persons" ON public.persons;
CREATE POLICY "Admin write persons"
  ON public.persons FOR INSERT
  TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.role = ANY (ARRAY['admin'::text, 'super_admin'::text])
  ));
