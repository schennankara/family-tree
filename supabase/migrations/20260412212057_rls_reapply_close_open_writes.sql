-- Already applied to production on 2026-04-12
-- Placeholder to keep migration history in sync
-- Re-applied the open write policy closures after rollback during troubleshooting

DROP POLICY IF EXISTS "Allow insert persons" ON public.persons;
DROP POLICY IF EXISTS "Allow update persons" ON public.persons;
DROP POLICY IF EXISTS "Allow delete persons" ON public.persons;

DROP POLICY IF EXISTS "Allow insert families" ON public.families;
DROP POLICY IF EXISTS "Allow update families" ON public.families;
DROP POLICY IF EXISTS "Allow delete families" ON public.families;
