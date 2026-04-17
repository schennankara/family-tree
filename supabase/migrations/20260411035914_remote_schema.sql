drop extension if exists "pg_net";
create sequence "public"."access_requests_id_seq";
create sequence "public"."edit_log_id_seq";
create sequence "public"."family_members_id_seq";
create sequence "public"."media_id_seq";
create sequence "public"."update_requests_id_seq";
create table "public"."access_requests" (
    "id" bigint not null default nextval('public.access_requests_id_seq'::regclass),
    "name" text not null,
    "email" text not null,
    "phone" text default ''::text,
    "person_id" text,
    "person_name" text default ''::text,
    "status" text not null default 'pending'::text,
    "admin_notes" text default ''::text,
    "resolved_by" uuid,
    "created_at" timestamp with time zone default now(),
    "resolved_at" timestamp with time zone
      );
alter table "public"."access_requests" enable row level security;
create table "public"."edit_log" (
    "id" bigint not null default nextval('public.edit_log_id_seq'::regclass),
    "person_id" text,
    "family_id" text,
    "action" text not null,
    "changes" jsonb,
    "edited_by" text default ''::text,
    "created_at" timestamp with time zone default now()
      );
alter table "public"."edit_log" enable row level security;
create table "public"."families" (
    "id" text not null,
    "husband_id" text,
    "wife_id" text,
    "marriage_date" text default ''::text,
    "marriage_place" text default ''::text,
    "children" text[] default '{}'::text[],
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );
alter table "public"."families" enable row level security;
create table "public"."family_members" (
    "id" bigint not null default nextval('public.family_members_id_seq'::regclass),
    "family_id" text not null,
    "person_id" text not null,
    "role" text not null,
    "birth_order" integer default 0,
    "created_at" timestamp with time zone default now()
      );
alter table "public"."family_members" enable row level security;
create table "public"."media" (
    "id" bigint not null default nextval('public.media_id_seq'::regclass),
    "cloudinary_url" text not null,
    "cloudinary_id" text default ''::text,
    "media_type" text default 'photo'::text,
    "file_name" text default ''::text,
    "caption" text default ''::text,
    "uploaded_by" text default ''::text,
    "uploaded_by_id" text default ''::text,
    "tagged_persons" text[] default '{}'::text[],
    "event_date" text default ''::text,
    "created_at" timestamp with time zone default now()
      );
alter table "public"."media" enable row level security;
create table "public"."persons" (
    "id" text not null,
    "first_name" text default ''::text,
    "middle_name" text default ''::text,
    "last_name" text default ''::text,
    "display_name" text default ''::text,
    "nickname" text default ''::text,
    "maiden_name" text default ''::text,
    "gender" text default ''::text,
    "date_of_birth" text default ''::text,
    "date_of_death" text default ''::text,
    "is_deceased" boolean default false,
    "birth_order" integer default 0,
    "email" text default ''::text,
    "phone" text default ''::text,
    "address1" text default ''::text,
    "address2" text default ''::text,
    "city" text default ''::text,
    "state" text default ''::text,
    "zip" text default ''::text,
    "country" text default ''::text,
    "facebook" text default ''::text,
    "instagram" text default ''::text,
    "linkedin" text default ''::text,
    "website" text default ''::text,
    "profile_photo" text default ''::text,
    "bio" text default ''::text,
    "location" text default ''::text,
    "profession" text default ''::text,
    "employer" text default ''::text,
    "stories" text default ''::text,
    "notes" text default ''::text,
    "photo_gallery_link" text default ''::text,
    "documents_link" text default ''::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "updated_by" text default ''::text
      );
alter table "public"."persons" enable row level security;
create table "public"."settings" (
    "key" text not null,
    "value" text not null default ''::text
      );
alter table "public"."settings" enable row level security;
create table "public"."update_requests" (
    "id" bigint not null default nextval('public.update_requests_id_seq'::regclass),
    "person_id" text,
    "person_name" text default ''::text,
    "requester_name" text not null,
    "requester_email" text not null,
    "request_type" text default 'update'::text,
    "changes" jsonb not null default '{}'::jsonb,
    "status" text not null default 'pending'::text,
    "admin_response" text default ''::text,
    "resolved_by" uuid,
    "created_at" timestamp with time zone default now(),
    "resolved_at" timestamp with time zone
      );
alter table "public"."update_requests" enable row level security;
create table "public"."users" (
    "id" uuid not null,
    "person_id" text,
    "name" text not null default ''::text,
    "email" text not null default ''::text,
    "phone" text default ''::text,
    "role" text not null default 'editor'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );
alter table "public"."users" enable row level security;
alter sequence "public"."access_requests_id_seq" owned by "public"."access_requests"."id";
alter sequence "public"."edit_log_id_seq" owned by "public"."edit_log"."id";
alter sequence "public"."family_members_id_seq" owned by "public"."family_members"."id";
alter sequence "public"."media_id_seq" owned by "public"."media"."id";
alter sequence "public"."update_requests_id_seq" owned by "public"."update_requests"."id";
CREATE UNIQUE INDEX access_requests_pkey ON public.access_requests USING btree (id);
CREATE UNIQUE INDEX edit_log_pkey ON public.edit_log USING btree (id);
CREATE UNIQUE INDEX families_pkey ON public.families USING btree (id);
CREATE UNIQUE INDEX family_members_family_id_person_id_key ON public.family_members USING btree (family_id, person_id);
CREATE UNIQUE INDEX family_members_pkey ON public.family_members USING btree (id);
CREATE INDEX idx_access_requests_status ON public.access_requests USING btree (status);
CREATE INDEX idx_edit_log_created ON public.edit_log USING btree (created_at);
CREATE INDEX idx_edit_log_person ON public.edit_log USING btree (person_id);
CREATE INDEX idx_families_husband ON public.families USING btree (husband_id);
CREATE INDEX idx_families_wife ON public.families USING btree (wife_id);
CREATE UNIQUE INDEX idx_family_one_husband ON public.family_members USING btree (family_id) WHERE (role = 'husband'::text);
CREATE UNIQUE INDEX idx_family_one_wife ON public.family_members USING btree (family_id) WHERE (role = 'wife'::text);
CREATE INDEX idx_fm_family ON public.family_members USING btree (family_id);
CREATE INDEX idx_fm_family_role ON public.family_members USING btree (family_id, role);
CREATE INDEX idx_fm_person ON public.family_members USING btree (person_id);
CREATE INDEX idx_persons_first_name_lower ON public.persons USING btree (lower(first_name));
CREATE INDEX idx_persons_last_name ON public.persons USING btree (last_name);
CREATE INDEX idx_update_requests_status ON public.update_requests USING btree (status);
CREATE INDEX idx_users_person ON public.users USING btree (person_id);
CREATE INDEX idx_users_role ON public.users USING btree (role);
CREATE UNIQUE INDEX media_pkey ON public.media USING btree (id);
CREATE UNIQUE INDEX persons_pkey ON public.persons USING btree (id);
CREATE UNIQUE INDEX settings_pkey ON public.settings USING btree (key);
CREATE UNIQUE INDEX update_requests_pkey ON public.update_requests USING btree (id);
CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);
alter table "public"."access_requests" add constraint "access_requests_pkey" PRIMARY KEY using index "access_requests_pkey";
alter table "public"."edit_log" add constraint "edit_log_pkey" PRIMARY KEY using index "edit_log_pkey";
alter table "public"."families" add constraint "families_pkey" PRIMARY KEY using index "families_pkey";
alter table "public"."family_members" add constraint "family_members_pkey" PRIMARY KEY using index "family_members_pkey";
alter table "public"."media" add constraint "media_pkey" PRIMARY KEY using index "media_pkey";
alter table "public"."persons" add constraint "persons_pkey" PRIMARY KEY using index "persons_pkey";
alter table "public"."settings" add constraint "settings_pkey" PRIMARY KEY using index "settings_pkey";
alter table "public"."update_requests" add constraint "update_requests_pkey" PRIMARY KEY using index "update_requests_pkey";
alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";
alter table "public"."access_requests" add constraint "access_requests_person_id_fkey" FOREIGN KEY (person_id) REFERENCES public.persons(id) not valid;
alter table "public"."access_requests" validate constraint "access_requests_person_id_fkey";
alter table "public"."access_requests" add constraint "access_requests_resolved_by_fkey" FOREIGN KEY (resolved_by) REFERENCES auth.users(id) not valid;
alter table "public"."access_requests" validate constraint "access_requests_resolved_by_fkey";
alter table "public"."access_requests" add constraint "access_requests_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]))) not valid;
alter table "public"."access_requests" validate constraint "access_requests_status_check";
alter table "public"."families" add constraint "families_husband_id_fkey" FOREIGN KEY (husband_id) REFERENCES public.persons(id) ON DELETE SET NULL not valid;
alter table "public"."families" validate constraint "families_husband_id_fkey";
alter table "public"."families" add constraint "families_wife_id_fkey" FOREIGN KEY (wife_id) REFERENCES public.persons(id) ON DELETE SET NULL not valid;
alter table "public"."families" validate constraint "families_wife_id_fkey";
alter table "public"."family_members" add constraint "family_members_family_id_fkey" FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE not valid;
alter table "public"."family_members" validate constraint "family_members_family_id_fkey";
alter table "public"."family_members" add constraint "family_members_family_id_person_id_key" UNIQUE using index "family_members_family_id_person_id_key";
alter table "public"."family_members" add constraint "family_members_person_id_fkey" FOREIGN KEY (person_id) REFERENCES public.persons(id) ON DELETE CASCADE not valid;
alter table "public"."family_members" validate constraint "family_members_person_id_fkey";
alter table "public"."family_members" add constraint "family_members_role_check" CHECK ((role = ANY (ARRAY['husband'::text, 'wife'::text, 'child'::text]))) not valid;
alter table "public"."family_members" validate constraint "family_members_role_check";
alter table "public"."update_requests" add constraint "update_requests_person_id_fkey" FOREIGN KEY (person_id) REFERENCES public.persons(id) not valid;
alter table "public"."update_requests" validate constraint "update_requests_person_id_fkey";
alter table "public"."update_requests" add constraint "update_requests_resolved_by_fkey" FOREIGN KEY (resolved_by) REFERENCES auth.users(id) not valid;
alter table "public"."update_requests" validate constraint "update_requests_resolved_by_fkey";
alter table "public"."update_requests" add constraint "update_requests_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'clarification'::text]))) not valid;
alter table "public"."update_requests" validate constraint "update_requests_status_check";
alter table "public"."users" add constraint "users_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;
alter table "public"."users" validate constraint "users_id_fkey";
alter table "public"."users" add constraint "users_person_id_fkey" FOREIGN KEY (person_id) REFERENCES public.persons(id) ON DELETE SET NULL not valid;
alter table "public"."users" validate constraint "users_person_id_fkey";
alter table "public"."users" add constraint "users_role_check" CHECK ((role = ANY (ARRAY['editor'::text, 'admin'::text, 'super_admin'::text]))) not valid;
alter table "public"."users" validate constraint "users_role_check";
set check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.create_family_user(p_email text, p_name text, p_person_id text DEFAULT NULL::text, p_role text DEFAULT 'editor'::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  new_user_id UUID;
  temp_password TEXT;
  encrypted_pw TEXT;
BEGIN
  temp_password := encode(gen_random_bytes(12), 'base64');
  encrypted_pw := crypt(temp_password, gen_salt('bf'));
  new_user_id := gen_random_uuid();
  
  INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    aud, role, created_at, updated_at,
    confirmation_token, recovery_token,
    email_change, email_change_token_new, email_change_token_current,
    email_change_confirm_status,
    phone, phone_change, phone_change_token,
    reauthentication_token, is_sso_user
  ) VALUES (
    new_user_id, '00000000-0000-0000-0000-000000000000',
    p_email, encrypted_pw,
    NOW(), '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('name', p_name),
    'authenticated', 'authenticated', NOW(), NOW(),
    encode(gen_random_bytes(32), 'hex'),
    encode(gen_random_bytes(32), 'hex'),
    '', '', '', 0,
    '', '', '',
    '', false
  );
  
  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  ) VALUES (
    new_user_id, new_user_id,
    jsonb_build_object('sub', new_user_id::text, 'email', p_email),
    'email', new_user_id::text,
    NOW(), NOW(), NOW()
  );
  
  INSERT INTO public.users (id, name, email, role, person_id)
  VALUES (new_user_id, p_name, p_email, p_role, p_person_id);
  
  RETURN json_build_object(
    'user_id', new_user_id,
    'email', p_email,
    'name', p_name,
    'role', p_role
  );
END;
$function$;
CREATE OR REPLACE FUNCTION public.is_in_edit_scope(editor_person_id text, target_person_id text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  editor_family_id TEXT;
  sibling_ids TEXT[];
  desc_check BOOLEAN;
BEGIN
  -- Can always edit self
  IF editor_person_id = target_person_id THEN RETURN TRUE; END IF;
  
  -- Find editor's parent family (famc)
  SELECT f.id, f.children INTO editor_family_id, sibling_ids
  FROM families f
  WHERE target_person_id = ANY(f.children)
    AND (editor_person_id = ANY(f.children));
  
  -- If both are in the same family as children, they're siblings
  IF editor_family_id IS NOT NULL THEN RETURN TRUE; END IF;
  
  -- Check if target is a descendant of editor
  -- Walk down from editor through families
  WITH RECURSIVE descendants AS (
    SELECT unnest(f.children) AS pid
    FROM families f
    WHERE f.husband_id = editor_person_id OR f.wife_id = editor_person_id
    UNION
    SELECT unnest(f.children) AS pid
    FROM families f
    JOIN descendants d ON f.husband_id = d.pid OR f.wife_id = d.pid
  )
  SELECT EXISTS (SELECT 1 FROM descendants WHERE pid = target_person_id) INTO desc_check;
  
  RETURN COALESCE(desc_check, FALSE);
END;
$function$;
CREATE OR REPLACE FUNCTION public.revert_to_snapshot(p_log_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  snapshot_data JSONB;
  person_data JSONB;
  family_data JSONB;
  fam JSONB;
BEGIN
  -- Get the snapshot
  SELECT changes INTO snapshot_data FROM edit_log WHERE id = p_log_id AND action = 'snapshot';
  
  IF snapshot_data IS NULL THEN
    RAISE EXCEPTION 'Snapshot not found';
  END IF;
  
  person_data := snapshot_data->'person';
  family_data := snapshot_data->'families';
  
  -- Restore person record
  UPDATE persons SET
    first_name = COALESCE(person_data->>'first_name', ''),
    middle_name = COALESCE(person_data->>'middle_name', ''),
    last_name = COALESCE(person_data->>'last_name', ''),
    display_name = COALESCE(person_data->>'display_name', ''),
    nickname = COALESCE(person_data->>'nickname', ''),
    maiden_name = COALESCE(person_data->>'maiden_name', ''),
    gender = COALESCE(person_data->>'gender', ''),
    date_of_birth = COALESCE(person_data->>'date_of_birth', ''),
    date_of_death = COALESCE(person_data->>'date_of_death', ''),
    is_deceased = COALESCE((person_data->>'is_deceased')::boolean, false),
    birth_order = COALESCE((person_data->>'birth_order')::integer, 0),
    email = COALESCE(person_data->>'email', ''),
    phone = COALESCE(person_data->>'phone', ''),
    address1 = COALESCE(person_data->>'address1', ''),
    address2 = COALESCE(person_data->>'address2', ''),
    city = COALESCE(person_data->>'city', ''),
    state = COALESCE(person_data->>'state', ''),
    zip = COALESCE(person_data->>'zip', ''),
    country = COALESCE(person_data->>'country', ''),
    facebook = COALESCE(person_data->>'facebook', ''),
    instagram = COALESCE(person_data->>'instagram', ''),
    linkedin = COALESCE(person_data->>'linkedin', ''),
    website = COALESCE(person_data->>'website', ''),
    profile_photo = COALESCE(person_data->>'profile_photo', ''),
    bio = COALESCE(person_data->>'bio', ''),
    location = COALESCE(person_data->>'location', ''),
    profession = COALESCE(person_data->>'profession', ''),
    employer = COALESCE(person_data->>'employer', ''),
    stories = COALESCE(person_data->>'stories', ''),
    notes = COALESCE(person_data->>'notes', ''),
    photo_gallery_link = COALESCE(person_data->>'photo_gallery_link', ''),
    documents_link = COALESCE(person_data->>'documents_link', ''),
    updated_by = 'revert'
  WHERE id = person_data->>'id';
  
  -- Restore family records (marriage date/place)
  IF family_data IS NOT NULL THEN
    FOR fam IN SELECT * FROM jsonb_array_elements(family_data)
    LOOP
      UPDATE families SET
        marriage_date = COALESCE(fam->>'marriage_date', ''),
        marriage_place = COALESCE(fam->>'marriage_place', '')
      WHERE id = fam->>'id';
    END LOOP;
  END IF;
  
  -- Log the revert
  INSERT INTO edit_log (person_id, action, edited_by, changes)
  VALUES (person_data->>'id', 'revert', 'admin', jsonb_build_object('reverted_from_snapshot', p_log_id));
  
  RETURN TRUE;
END;
$function$;
CREATE OR REPLACE FUNCTION public.snapshot_person(p_person_id text, p_reason text DEFAULT 'before_approve'::text)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  person_data JSONB;
  family_data JSONB;
  log_id BIGINT;
BEGIN
  -- Capture full person record
  SELECT to_jsonb(p.*) INTO person_data FROM persons p WHERE p.id = p_person_id;
  
  -- Capture family data (marriage info)
  SELECT jsonb_agg(to_jsonb(f.*)) INTO family_data 
  FROM families f 
  WHERE f.husband_id = p_person_id OR f.wife_id = p_person_id;
  
  -- Store as snapshot in edit_log
  INSERT INTO edit_log (person_id, action, changes, edited_by)
  VALUES (
    p_person_id,
    'snapshot',
    jsonb_build_object('person', person_data, 'families', family_data, 'reason', p_reason),
    'system'
  )
  RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$function$;
CREATE OR REPLACE FUNCTION public.update_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$;
grant delete on table "public"."access_requests" to "anon";
grant insert on table "public"."access_requests" to "anon";
grant references on table "public"."access_requests" to "anon";
grant select on table "public"."access_requests" to "anon";
grant trigger on table "public"."access_requests" to "anon";
grant truncate on table "public"."access_requests" to "anon";
grant update on table "public"."access_requests" to "anon";
grant delete on table "public"."access_requests" to "authenticated";
grant insert on table "public"."access_requests" to "authenticated";
grant references on table "public"."access_requests" to "authenticated";
grant select on table "public"."access_requests" to "authenticated";
grant trigger on table "public"."access_requests" to "authenticated";
grant truncate on table "public"."access_requests" to "authenticated";
grant update on table "public"."access_requests" to "authenticated";
grant delete on table "public"."access_requests" to "service_role";
grant insert on table "public"."access_requests" to "service_role";
grant references on table "public"."access_requests" to "service_role";
grant select on table "public"."access_requests" to "service_role";
grant trigger on table "public"."access_requests" to "service_role";
grant truncate on table "public"."access_requests" to "service_role";
grant update on table "public"."access_requests" to "service_role";
grant delete on table "public"."edit_log" to "anon";
grant insert on table "public"."edit_log" to "anon";
grant references on table "public"."edit_log" to "anon";
grant select on table "public"."edit_log" to "anon";
grant trigger on table "public"."edit_log" to "anon";
grant truncate on table "public"."edit_log" to "anon";
grant update on table "public"."edit_log" to "anon";
grant delete on table "public"."edit_log" to "authenticated";
grant insert on table "public"."edit_log" to "authenticated";
grant references on table "public"."edit_log" to "authenticated";
grant select on table "public"."edit_log" to "authenticated";
grant trigger on table "public"."edit_log" to "authenticated";
grant truncate on table "public"."edit_log" to "authenticated";
grant update on table "public"."edit_log" to "authenticated";
grant delete on table "public"."edit_log" to "service_role";
grant insert on table "public"."edit_log" to "service_role";
grant references on table "public"."edit_log" to "service_role";
grant select on table "public"."edit_log" to "service_role";
grant trigger on table "public"."edit_log" to "service_role";
grant truncate on table "public"."edit_log" to "service_role";
grant update on table "public"."edit_log" to "service_role";
grant delete on table "public"."families" to "anon";
grant insert on table "public"."families" to "anon";
grant references on table "public"."families" to "anon";
grant select on table "public"."families" to "anon";
grant trigger on table "public"."families" to "anon";
grant truncate on table "public"."families" to "anon";
grant update on table "public"."families" to "anon";
grant delete on table "public"."families" to "authenticated";
grant insert on table "public"."families" to "authenticated";
grant references on table "public"."families" to "authenticated";
grant select on table "public"."families" to "authenticated";
grant trigger on table "public"."families" to "authenticated";
grant truncate on table "public"."families" to "authenticated";
grant update on table "public"."families" to "authenticated";
grant delete on table "public"."families" to "service_role";
grant insert on table "public"."families" to "service_role";
grant references on table "public"."families" to "service_role";
grant select on table "public"."families" to "service_role";
grant trigger on table "public"."families" to "service_role";
grant truncate on table "public"."families" to "service_role";
grant update on table "public"."families" to "service_role";
grant delete on table "public"."family_members" to "anon";
grant insert on table "public"."family_members" to "anon";
grant references on table "public"."family_members" to "anon";
grant select on table "public"."family_members" to "anon";
grant trigger on table "public"."family_members" to "anon";
grant truncate on table "public"."family_members" to "anon";
grant update on table "public"."family_members" to "anon";
grant delete on table "public"."family_members" to "authenticated";
grant insert on table "public"."family_members" to "authenticated";
grant references on table "public"."family_members" to "authenticated";
grant select on table "public"."family_members" to "authenticated";
grant trigger on table "public"."family_members" to "authenticated";
grant truncate on table "public"."family_members" to "authenticated";
grant update on table "public"."family_members" to "authenticated";
grant delete on table "public"."family_members" to "service_role";
grant insert on table "public"."family_members" to "service_role";
grant references on table "public"."family_members" to "service_role";
grant select on table "public"."family_members" to "service_role";
grant trigger on table "public"."family_members" to "service_role";
grant truncate on table "public"."family_members" to "service_role";
grant update on table "public"."family_members" to "service_role";
grant delete on table "public"."media" to "anon";
grant insert on table "public"."media" to "anon";
grant references on table "public"."media" to "anon";
grant select on table "public"."media" to "anon";
grant trigger on table "public"."media" to "anon";
grant truncate on table "public"."media" to "anon";
grant update on table "public"."media" to "anon";
grant delete on table "public"."media" to "authenticated";
grant insert on table "public"."media" to "authenticated";
grant references on table "public"."media" to "authenticated";
grant select on table "public"."media" to "authenticated";
grant trigger on table "public"."media" to "authenticated";
grant truncate on table "public"."media" to "authenticated";
grant update on table "public"."media" to "authenticated";
grant delete on table "public"."media" to "service_role";
grant insert on table "public"."media" to "service_role";
grant references on table "public"."media" to "service_role";
grant select on table "public"."media" to "service_role";
grant trigger on table "public"."media" to "service_role";
grant truncate on table "public"."media" to "service_role";
grant update on table "public"."media" to "service_role";
grant delete on table "public"."persons" to "anon";
grant insert on table "public"."persons" to "anon";
grant references on table "public"."persons" to "anon";
grant select on table "public"."persons" to "anon";
grant trigger on table "public"."persons" to "anon";
grant truncate on table "public"."persons" to "anon";
grant update on table "public"."persons" to "anon";
grant delete on table "public"."persons" to "authenticated";
grant insert on table "public"."persons" to "authenticated";
grant references on table "public"."persons" to "authenticated";
grant select on table "public"."persons" to "authenticated";
grant trigger on table "public"."persons" to "authenticated";
grant truncate on table "public"."persons" to "authenticated";
grant update on table "public"."persons" to "authenticated";
grant delete on table "public"."persons" to "service_role";
grant insert on table "public"."persons" to "service_role";
grant references on table "public"."persons" to "service_role";
grant select on table "public"."persons" to "service_role";
grant trigger on table "public"."persons" to "service_role";
grant truncate on table "public"."persons" to "service_role";
grant update on table "public"."persons" to "service_role";
grant delete on table "public"."settings" to "anon";
grant insert on table "public"."settings" to "anon";
grant references on table "public"."settings" to "anon";
grant select on table "public"."settings" to "anon";
grant trigger on table "public"."settings" to "anon";
grant truncate on table "public"."settings" to "anon";
grant update on table "public"."settings" to "anon";
grant delete on table "public"."settings" to "authenticated";
grant insert on table "public"."settings" to "authenticated";
grant references on table "public"."settings" to "authenticated";
grant select on table "public"."settings" to "authenticated";
grant trigger on table "public"."settings" to "authenticated";
grant truncate on table "public"."settings" to "authenticated";
grant update on table "public"."settings" to "authenticated";
grant delete on table "public"."settings" to "service_role";
grant insert on table "public"."settings" to "service_role";
grant references on table "public"."settings" to "service_role";
grant select on table "public"."settings" to "service_role";
grant trigger on table "public"."settings" to "service_role";
grant truncate on table "public"."settings" to "service_role";
grant update on table "public"."settings" to "service_role";
grant delete on table "public"."update_requests" to "anon";
grant insert on table "public"."update_requests" to "anon";
grant references on table "public"."update_requests" to "anon";
grant select on table "public"."update_requests" to "anon";
grant trigger on table "public"."update_requests" to "anon";
grant truncate on table "public"."update_requests" to "anon";
grant update on table "public"."update_requests" to "anon";
grant delete on table "public"."update_requests" to "authenticated";
grant insert on table "public"."update_requests" to "authenticated";
grant references on table "public"."update_requests" to "authenticated";
grant select on table "public"."update_requests" to "authenticated";
grant trigger on table "public"."update_requests" to "authenticated";
grant truncate on table "public"."update_requests" to "authenticated";
grant update on table "public"."update_requests" to "authenticated";
grant delete on table "public"."update_requests" to "service_role";
grant insert on table "public"."update_requests" to "service_role";
grant references on table "public"."update_requests" to "service_role";
grant select on table "public"."update_requests" to "service_role";
grant trigger on table "public"."update_requests" to "service_role";
grant truncate on table "public"."update_requests" to "service_role";
grant update on table "public"."update_requests" to "service_role";
grant delete on table "public"."users" to "anon";
grant insert on table "public"."users" to "anon";
grant references on table "public"."users" to "anon";
grant select on table "public"."users" to "anon";
grant trigger on table "public"."users" to "anon";
grant truncate on table "public"."users" to "anon";
grant update on table "public"."users" to "anon";
grant delete on table "public"."users" to "authenticated";
grant insert on table "public"."users" to "authenticated";
grant references on table "public"."users" to "authenticated";
grant select on table "public"."users" to "authenticated";
grant trigger on table "public"."users" to "authenticated";
grant truncate on table "public"."users" to "authenticated";
grant update on table "public"."users" to "authenticated";
grant delete on table "public"."users" to "service_role";
grant insert on table "public"."users" to "service_role";
grant references on table "public"."users" to "service_role";
grant select on table "public"."users" to "service_role";
grant trigger on table "public"."users" to "service_role";
grant truncate on table "public"."users" to "service_role";
grant update on table "public"."users" to "service_role";
create policy "Admin resolve access requests"
  on "public"."access_requests"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['admin'::text, 'super_admin'::text]))))));
create policy "Anyone can request access"
  on "public"."access_requests"
  as permissive
  for insert
  to public
with check (true);
create policy "Read access requests"
  on "public"."access_requests"
  as permissive
  for select
  to public
using (true);
create policy "Allow insert edit_log"
  on "public"."edit_log"
  as permissive
  for insert
  to public
with check (true);
create policy "Public read edit_log"
  on "public"."edit_log"
  as permissive
  for select
  to public
using (true);
create policy "Admin delete families"
  on "public"."families"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['admin'::text, 'super_admin'::text]))))));
create policy "Admin update families"
  on "public"."families"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['admin'::text, 'super_admin'::text]))))));
create policy "Admin write families"
  on "public"."families"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['admin'::text, 'super_admin'::text]))))));
create policy "Allow delete families"
  on "public"."families"
  as permissive
  for delete
  to anon, authenticated
using (true);
create policy "Allow insert families"
  on "public"."families"
  as permissive
  for insert
  to anon, authenticated
with check (true);
create policy "Allow update families"
  on "public"."families"
  as permissive
  for update
  to anon, authenticated
using (true);
create policy "Public read families"
  on "public"."families"
  as permissive
  for select
  to public
using (true);
create policy "Anon delete family_members"
  on "public"."family_members"
  as permissive
  for delete
  to anon
using (true);
create policy "Anon update family_members"
  on "public"."family_members"
  as permissive
  for update
  to anon
using (true);
create policy "Anon write family_members"
  on "public"."family_members"
  as permissive
  for insert
  to anon
with check (true);
create policy "Auth delete family_members"
  on "public"."family_members"
  as permissive
  for delete
  to authenticated
using (true);
create policy "Auth update family_members"
  on "public"."family_members"
  as permissive
  for update
  to authenticated
using (true);
create policy "Auth write family_members"
  on "public"."family_members"
  as permissive
  for insert
  to authenticated
with check (true);
create policy "Public read family_members"
  on "public"."family_members"
  as permissive
  for select
  to public
using (true);
create policy "Allow delete media"
  on "public"."media"
  as permissive
  for delete
  to anon, authenticated
using (true);
create policy "Allow insert media"
  on "public"."media"
  as permissive
  for insert
  to anon, authenticated
with check (true);
create policy "Allow update media"
  on "public"."media"
  as permissive
  for update
  to anon, authenticated
using (true);
create policy "Public read media"
  on "public"."media"
  as permissive
  for select
  to public
using (true);
create policy "Admin delete persons"
  on "public"."persons"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['admin'::text, 'super_admin'::text]))))));
create policy "Admin update persons"
  on "public"."persons"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['admin'::text, 'super_admin'::text]))))));
create policy "Admin write persons"
  on "public"."persons"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['admin'::text, 'super_admin'::text]))))));
create policy "Allow delete persons"
  on "public"."persons"
  as permissive
  for delete
  to anon, authenticated
using (true);
create policy "Allow insert persons"
  on "public"."persons"
  as permissive
  for insert
  to anon, authenticated
with check (true);
create policy "Allow update persons"
  on "public"."persons"
  as permissive
  for update
  to anon, authenticated
using (true);
create policy "Editor update persons"
  on "public"."persons"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users u
  WHERE ((u.id = auth.uid()) AND (u.role = 'editor'::text) AND public.is_in_edit_scope(u.person_id, persons.id)))));
create policy "Public read persons"
  on "public"."persons"
  as permissive
  for select
  to public
using (true);
create policy "Public read settings"
  on "public"."settings"
  as permissive
  for select
  to public
using (true);
create policy "Super admin modify settings"
  on "public"."settings"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.role = 'super_admin'::text)))));
create policy "Admin resolve update requests"
  on "public"."update_requests"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['admin'::text, 'super_admin'::text]))))));
create policy "Anyone can submit updates"
  on "public"."update_requests"
  as permissive
  for insert
  to public
with check (true);
create policy "Read update requests"
  on "public"."update_requests"
  as permissive
  for select
  to public
using (true);
create policy "Anon read users"
  on "public"."users"
  as permissive
  for select
  to anon
using (true);
create policy "Authenticated read users"
  on "public"."users"
  as permissive
  for select
  to authenticated
using (true);
create policy "Super admin delete users"
  on "public"."users"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users users_1
  WHERE ((users_1.id = auth.uid()) AND (users_1.role = 'super_admin'::text)))));
create policy "Super admin manage users"
  on "public"."users"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.users users_1
  WHERE ((users_1.id = auth.uid()) AND (users_1.role = 'super_admin'::text)))));
create policy "Super admin update users"
  on "public"."users"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users users_1
  WHERE ((users_1.id = auth.uid()) AND (users_1.role = ANY (ARRAY['super_admin'::text, 'admin'::text]))))));
CREATE TRIGGER families_updated_at BEFORE UPDATE ON public.families FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER persons_updated_at BEFORE UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
