# FTLS Project Architecture & Status

## What is FTLS?
FTLS (Family Tree Living Site/System) is a private family portal for the Chennamkara family lineage from Kerala, India. It's NOT competing with Ancestry or FamilySearch — it's a private engagement platform for one extended family with diaspora across US, UK, and India.

## Key People
- **Steve Chennankara** (Super Admin, primary developer) — Psychiatrist in Grapevine/Colleyville, TX
- **Rolson Chennamkara Abraham** — family admin, has his own genealogy app
- **Abey Rajan** — family admin, uses Family Tree 11 app, his GEDCOM seeded the Supabase DB

## Live Site
- **URL:** https://schennankara.github.io/family-tree/
- **Architecture:** Single HTML file (React/Babel via CDN) + Supabase backend
- **Supabase project:** https://hnsikxxbpyhsybqmjgss.supabase.co

## Database Schema (Supabase)

### persons table
Core fields: id, first_name, middle_name, last_name, display_name, nickname, maiden_name, gender, date_of_birth, date_of_death, is_deceased, birth_order
Contact: email, phone, address1, address2, city, state, zip, country, location
Social: facebook, instagram, linkedin, website
Profile: profile_photo, bio, profession, employer
Content: stories, notes, photo_gallery_link, documents_link
GEDCOM passthrough: _extra_gedcom (text), title_prefix (text), burial_date (text)
Meta: created_at, updated_at, updated_by

### families table
Fields: id, husband_id, wife_id, marriage_date, marriage_place, children (text array), _extra_gedcom (text), created_at, updated_at

### gedcom_meta table
Fields: id (text PK), record_type (text: 'OBJE' or 'NOTE'), raw_gedcom (text)
Purpose: Store top-level GEDCOM records (photos, notes) that don't map to persons/families

### edit_log table
Tracks all changes with previous values for rollback capability

### family_roles table
Maps user emails to person IDs and roles (super_admin, admin, editor, member, viewer)

## Data Statistics (as of April 2026)
- 769 total persons
- 236 families
- 348 blood Chennamkara descendants (from Mathan Mathai)
- 140 spouses of blood members
- 281 disconnected persons (in-law families: Punnose, Oommen, Chacko, Alexander, Varghese, Thomas)
- 286 OBJE (photo) references in gedcom_meta
- 64 NOTE records in gedcom_meta
- 734 persons with _extra_gedcom data

## Family Lineage Backbone
Mathan Mathai (G0) → Kochukunju Mattapallil (G1) → Thomas Mathew (G2) → Soman Chennankara (G3) → Steve Chennankara (G4) → Henry/Chelsea (G5)

## Key Bridge Marriages (connecting Chennamkara to in-law clans)
1. **T O Jacob ⚭ Joy Jacob** — bridges Punnose/Oommen clan (largest: ~200 people)
2. **Aleyamma Abraham ⚭ George Chennamkara Abraham** — Oommen to Chennamkara
3. **Sheeba Abraham ⚭ Rolson Chennamkara Abraham** — Alexander to Chennamkara
4. **Arun Kumar Samuel ⚭ Rincy Samuel** — Kumar family

## In-Law Clan Root Ancestors (disconnected sub-trees)
- **Punnose Punnose & Mrs Punnose** → 6 children including Oommen Punnose, Mathai Punnose
- **Oommen Punnose & Mariamma Punnose** → 8 children (the T O generation)
- **C.C Thomas & Pennamma Thomas** → 8 children
- **C.T Varghese & Ponnamma Varghese** → 3 children
- **K.C Mathew & Mariamma Mathew** → Ann (Mini) Chacko, Jacob Mathew
- **K S Alexander & Mariamma Alexander** → Sheeba (married Rolson), Gladson, Glady
- **Annamma George & T.M George** → 7 children (Philip George, Joy George, etc.)

## Five-Tier Access System (designed, partially built)
1. **Public Viewer** — general family password
2. **Family Member** — submits edit requests for approval
3. **Family Editor** — verified, can edit own branch
4. **Admin** (Rolson, Abey) — direct edits, manages approval queue
5. **Super Admin** (Steve) — full access

## Current Features (v4.7.0)
- Tree visualization (pedigree style, squares=male, circles=female)
- Person detail panel with editing
- Search bar
- Photo upload (Cloudinary)
- Diff & Merge tool (compare external GEDCOM with FTLS data)
- Three export modes: full GEDCOM, diff fragment, merged GEDCOM
- _extra_gedcom passthrough for lossless GEDCOM round trip
- Backfill tool (populate DB fields from GEDCOM without overwriting)
- Edit log with rollback capability
- Family password gate + admin login (Supabase Auth)

## Diff & Merge Tool — Safety Rules
- **Changed tab (Family Members):** Individual import toggle only (no bulk import). "⬆ All Export" allowed. "⚠ would clear" warning when importing would blank FTLS data.
- **External Only tab:** Bulk import allowed for new people connected to tree. Individual toggle for unconnected.
- **FTLS Only tab:** Bulk export always allowed.
- **Others section (in Changed tab):** Read-only. Pass through unchanged in merged exports.

## Known Issues / Edge Cases
- **Daine Chennankara** has two FAMS in Abey's GEDCOM: first marriage (divorced, no wife name, 2 unnamed placeholder children @74518604@ and @199744@) and current marriage to Jensine. First marriage data not in FTLS. The nameless children cause orphan records in diffs.
- **is_deceased** must be explicit boolean/null, NOT derived from DEAT tag presence (empty DEAT tags exist)
- **NAME/TYPE lookahead bug** in GEDCOM: a TYPE nick on second NAME record can suppress primary name if parser doesn't scope NAME blocks
- **BOM and carriage return** normalization required when parsing GEDCOM files
- **Abey's mass-import incident (April 13, 2026):** Used diff tool to bulk-import, wiped Steve's family data. Rolled back via edit_log. Led to removing "All Import" button for changed persons.

## GEDCOM Source Files
- **Primary (Supabase version):** Chennankara_or_Chennamkara11.ged (736 people, 227 families, 286 OBJE)
- **Next.js version:** Chennamkara_1.ged (644 people, older)

## Tech Stack
- **Frontend:** Single HTML file, React 18 via CDN, Babel transpiler
- **Backend:** Supabase (PostgreSQL + Auth + RLS)
- **Hosting:** GitHub Pages (schennankara.github.io/family-tree/)
- **Photos:** Cloudinary
- **Visualization:** Custom D3-based tree (planned: integrate Topola patterns)
- **Email notifications:** Resend (planned, free tier)

## Design Preferences
- Dark theme: background #0a0805, gold accent #c4a35a, male #a8c9ad, female #b8aed4
- Swim-lane visualization REJECTED — pedigree tree preferred
- Squares for males, circles for females, collapsible branches
- Single HTML file architecture preferred for deployment simplicity
