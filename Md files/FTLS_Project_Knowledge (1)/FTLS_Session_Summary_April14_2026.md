# FTLS Session Summary — April 14, 2026

## Session Focus
GEDCOM round-trip lossless export, diff/merge UI overhaul, export consolidation to single shared function, CONT/CONC parser fix, Abey rollback, multi-family research.

---

## COMPLETED

### 1. `_extra_gedcom` Infrastructure (Schema + Backfill)
- New columns: `persons._extra_gedcom`, `persons.title_prefix`, `persons.burial_date`, `families._extra_gedcom`
- New table: `gedcom_meta` (id, record_type, raw_gedcom) for top-level OBJE/NOTE records
- Backfill from `Chennankara_or_Chennamkara11.ged`: 734 persons, 226 families, 286 OBJE, 64 NOTE records
- 60 addresses, 8 title prefixes, 8 burial dates, 4 professions populated

### 2. Shared `personToGedcomLines()` Function (MAJOR REFACTOR)
- Single top-level function (line ~823) that converts a FTLS person object → GEDCOM INDI lines
- **Eliminated 4 separate inline INDI builders** that were each missing different fields
- Used by ALL 4 export callers:
  1. `buildIndi()` in full export
  2. `buildReplacementIndi()` in merged export (existing persons)
  3. New person insertion in merged export
  4. Fragment diff export (`exportDiffGedcom`)
- Fields covered: NAME (GIVN/SURN), nick, maiden, SEX, BIRT (DATE/PLAC), DEAT, PHON, EMAI, ADDR (CITY/STAE/POST/CTRY), OCCU, WWW, NOTE (with CONT for multi-line), BIO, STORY, _FACEBOOK, _INSTAGRAM, _LINKEDIN, _PHOTO, _EMPLOYER, _PHOTOGALLERY, _DOCUMENTS

### 3. CONT/CONC Parser Fix
- Both parsers (`parseGedcomFile` line ~1602 and `migrateGedcomToSupabase` line ~556) now handle CONT/CONC
- CONT appends with newline, CONC concatenates directly
- Export uses `pushNote()` helper inside `personToGedcomLines` to split multi-line text back into CONT lines
- Fixes: Rolson's long notes were being truncated to first line

### 4. Merged Export — Single Path (MAJOR SIMPLIFICATION)
- Removed dual-path approach (full replacement vs surgical field patching)
- ONE path for all existing persons in `buildMergedGedcom`: extract cardinal features → build fresh INDI via `personToGedcomLines` → append cardinal features → replace original block
- Cardinal features = any level-1 tag NOT in KNOWN_EXPORT_L1 set (catches OBJE, RESI, BURI, _CRE, CHAN, DIV)
- ~115 lines of surgical patching code removed
- No more partial field export — when exporting a changed person, ALL FTLS data goes out

### 5. Diff & Merge UI Safety Rules
- **Changed tab:** Individual import only (no bulk import). Bulk export allowed. `⚠ would clear` warning when importing would blank FTLS data.
- **External Only tab:** Bulk import for connected persons. Individual for unconnected.
- **FTLS Only tab:** Bulk export always allowed.
- **Others section:** Read-only, collapsed. Pass through unchanged in merged exports.
- Removed redundant New Family Members and FTLS Only sections from Changed tab (they have own tabs)

### 6. Lineage Breadcrumbs
- Replaced parent/sibling breadcrumbs with ancestor chain: `Mathan → Kochukunju → Thomas → Soman → Steve`
- Married-in spouses show: `⚭ Steve Chennankara`
- `⚠ Different lineage` when FTLS and EXT paths diverge

### 7. Abey's Destructive Import Rolled Back
- 53 edits on 2026-04-13, most destructive
- 21 UPDATE statements restored all previous values from edit_log
- Abey added zero new people — all were updates to existing records
- Two legitimate changes preserved: Thomas Kulanjikompil birth date, Jenson Vargheese name

### 8. React useState Hook Fix
- `showAddrOnly`/`showOthers` were inside conditional IIFE — violated Rules of Hooks, caused blank screen
- Moved to GedcomDiffModal component level

### 9. Disconnected Persons Analysis
- 281 of 769 persons not reachable from Mathan Mathai
- In-law families connected through marriages
- Key bridges: T O Jacob ⚭ Joy Jacob, Aleyamma ⚭ George C. Abraham, Sheeba ⚭ Rolson
- Root in-law ancestors: Punnose, Oommen, Thomas, Varghese, Alexander, Mathew clans

---

## KEY BUGS FOUND & FIXED

1. **Merged export not writing changes** — `changed_fields` went through field-level patching with incomplete tagMap. Fixed by single path.
2. **New persons in merged export missing fields** — inline builder only wrote NAME/SEX/BIRT/DEAT/PHON/EMAI. Fixed by `personToGedcomLines`.
3. **Fragment export missing fields** — `exportDiffGedcom` had its own incomplete inline builder. Fixed.
4. **Middle name collision** — old tagMap mapped `mn` to `NAME>GIVN` same as `fn`. Eliminated.
5. **CONT/CONC not parsed** — long notes truncated. Fixed in both parsers.
6. **useState in IIFE** — blank screen on Changed tab click. Moved to component level.

---

## KEY DECISIONS

1. No partial field export — ALL FTLS data goes out with cardinal features preserved
2. One shared function `personToGedcomLines` — single source of truth for person→GEDCOM
3. No bulk import for changed persons — individual review only
4. Others section read-only — pass through unchanged
5. Export always safe — never modifies FTLS database
6. Daine's first marriage: tell Abey to enter real names or remove placeholders

---

## PENDING FOR NEXT SESSION

### Multi-Family Network Visualization
- Auto-detect family clusters from graph structure
- Build `family_clusters` and `person_clusters` tables
- Three-level visualization: Cluster Map → Family Tree → Person Detail
- See FTLS_Multi_Family_Roadmap.md and FTLS_Open_Source_Knowledge_Base.md

### Other Pending
- `diffPerson` doesn't compare all fields (missing: stories, a2, emp, ws, fb, ig, li, pp, pgl, dl, dec)
- `dec` (is_deceased) export can add DEAT tag to someone who didn't have one
- Abey's benign name reformats still in DB (T+O → "T O")
- Daine's first marriage placeholder children in Abey's GEDCOM
