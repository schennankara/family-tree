# FTLS index.html — Code Structure & Function Reference

**File:** `index.html` (single-file React app, ~5641 lines)
**Version:** v4.7.1 (post-consolidation)
**Stack:** React 18 via CDN, Babel transpiler, Supabase JS client
**Live:** https://schennankara.github.io/family-tree/

---

## File Layout Overview

```
Lines 1-42        HTML head, CDN imports (React, Babel, Supabase, Cloudinary)
Lines 43-66       Environment config (Supabase URL, anon key, Cloudinary)
Lines 67-130      Utility functions (image resize, Cloudinary upload, media)
Lines 131-275     Supabase data layer (load, build tree, save person)
Lines 274-540     CRUD operations (save, delete, add person, spouse, move branch)
Lines 543-730     GEDCOM migration (parse GEDCOM → write to Supabase) — includes CONT/CONC
Lines 731-822     MigrateDialog component
Lines 823-883     SHARED: personToGedcomLines() — single source of truth for person→GEDCOM
Lines 884-1078    GEDCOM full export (exportTreeToGedcom, downloadGedcom)
Lines 1079-1260   Diff engine (diffPerson, fuzzyMatch, computeGedcomDiff)
Lines 1258-1465   Merge operations (mergePersonToDb, mergeFieldsToDb, exportDiffGedcom)
Lines 1464-1600   Merged GEDCOM export (buildMergedGedcom) — single path, cardinal preservation
Lines 1602-1960   GEDCOM parser (parseGedcomFile, parseIndi, parseFam, buildTreeFromFlat) — includes CONT/CONC
Lines 1957-2030   Import GEDCOM trigger, persistAuth
Lines 2030-2290   Auth system (getHeaders, canEdit, role checks, branch permissions)
Lines 2294-2665   Auth UI components (PasswordReset, Login, RequestAccount, ViewerIdentity)
Lines 2666-3178   AdminPanel component
Lines 3180-3296   EditForm component
Lines 3297-3344   TreeNode component
Lines 3345-3462   Detail component (person detail side panel)
Lines 3463-3608   PhotoGallery component
Lines 3609-3751   MediaUploadModal component
Lines 3752-4412   GedcomDiffModal component (diff & merge tool)
Lines 4413-4622   MoveBranchModal component
Lines 4623-4998   BackfillModal component
Lines 4999-5641   App component (main application)
```

---

## CRITICAL: Shared Function — personToGedcomLines (Line 823)

**This is the SINGLE SOURCE OF TRUTH for converting a person object to GEDCOM lines.**

All 4 export paths call this function. If you add a new field to the person object, add it here ONCE and it flows everywhere.

```javascript
function personToGedcomLines(person) → string[]
```

Returns array of GEDCOM lines (including `0 @ID@ INDI` header). Does NOT include FAMS/FAMC (caller adds those) or `_xg` passthrough (caller adds those).

Fields written: NAME (GIVN/SURN), nick (TYPE nick), maiden (TYPE birth), SEX, BIRT (DATE/PLAC), DEAT, PHON, EMAI, ADDR (ADR2/CITY/STAE/POST/CTRY), OCCU, WWW, NOTE (with CONT for multi-line via pushNote helper), BIO, STORY, _FACEBOOK, _INSTAGRAM, _LINKEDIN, _PHOTO, _EMPLOYER, _PHOTOGALLERY, _DOCUMENTS.

### 4 Callers:

1. **`buildIndi(person)`** (line ~919) — Full export. Adds FAMS/FAMC from tree lookup, appends `_xg` or CHAN timestamp.
2. **`buildReplacementIndi(p)`** (line ~1547) — Merged export (existing persons). Adds FAMS/FAMC from familyMap, appends `_xg`.
3. **New person insertion** (line ~1497) — Merged export (new persons). Adds FAMS/FAMC from familyMap, appends `_xg`.
4. **`exportDiffGedcom`** (line ~1375) — Fragment export. Adds FAMS/FAMC from lookup, appends `_xg` or CHAN.

---

## Supabase Data Layer (Lines 167-275)

| Function | Line | Purpose |
|----------|------|---------|
| `loadFromSupabase()` | 167 | Load all persons + families from Supabase |
| `buildTreeFromDB(persons, families)` | 184 | Convert flat DB rows → hierarchical tree. Loads `_extra_gedcom`, `title_prefix`, `burial_date`. |

### Tree Node Shape
```javascript
{
  id, fn, mn, ln, dn, nk, md, g, dob, dod, dec, bo,
  em, ph, a1, a2, ci, st, zp, co,
  fb, ig, li, ws, pp, bio, loc, prof, emp,
  stories, notes, pgl, dl, tp, burd, _xg,
  gen, spouse, children, _raw
}
```

---

## CRUD Operations (Lines 274-540)

| Function | Line | Purpose |
|----------|------|---------|
| `savePerson(person, editUser)` | 274 | Upsert person. Logs to edit_log with previous values. |
| `saveFamily(...)` | 359 | Upsert family record |
| `deletePersonFromDB(personId, editUser)` | 373 | Delete person + clean up families |
| `addPersonToDB(person, parentId, editUser)` | 402 | Add new person + create/update family link |
| `saveSpouseToDB(parentId, spouse, editUser)` | 443 | Add spouse to person |
| `deleteSpouseFromDB(parentId, spouseId, editUser)` | 467 | Remove spouse |
| `movePersonBranch(personId, from, to, editUser)` | 480 | Move person between families |

---

## GEDCOM Migration (Lines 543-730)

| Function | Line | Purpose |
|----------|------|---------|
| `migrateGedcomToSupabase(gedcomText, onProgress)` | 556 | Full GEDCOM → Supabase. ⚠️ Destructive. Handles CONT/CONC, NAME/TYPE, BOM, empty DEAT. |

---

## GEDCOM Export (Lines 884-1078)

| Function | Line | Purpose |
|----------|------|---------|
| `exportTreeToGedcom(tree, personMap, familyMap)` | 884 | Full tree → GEDCOM via `buildIndi` → `personToGedcomLines` |
| `downloadGedcom(tree, personMap, familyMap)` | 1038 | Async. Loads gedcom_meta, appends OBJE/NOTE before TRLR |

---

## Diff Engine (Lines 1079-1260)

| Function | Line | Purpose |
|----------|------|---------|
| `diffPerson(ftls, ext)` | 1079 | Compare two persons. Fields: fn, mn, ln, nk, md, g, dob, dod, loc, ph, em, prof, a1, ci, st, co, zp, notes, bio |
| `fuzzyMatchPerson(person, candidates)` | 1099 | Score-based name+DOB matching |
| `computeGedcomDiff(...)` | 1129 | Main diff. Returns matched/extOnly/ftlsOnly/fuzzyMatched/familyDiffs |

**Note:** `diffPerson` does NOT compare: stories, a2, emp, ws, fb, ig, li, pp, pgl, dl, dec. These fields will be silently included in exports but won't show as diffs.

---

## Merge Operations (Lines 1258-1465)

| Function | Line | Purpose |
|----------|------|---------|
| `mergePersonToDb(ext, editUser)` | 1258 | Import external person to Supabase |
| `mergeFamilyToDb(extFam)` | 1276 | Import/update family, merge children |
| `mergeFieldsToDb(ftlsPerson, fields, ext, editUser)` | 1315 | Import specific fields to existing person |
| `exportDiffGedcom(...)` | 1345 | Fragment GEDCOM via `personToGedcomLines` |

---

## Merged GEDCOM Export (Lines 1464-1600)

| Function | Line | Purpose |
|----------|------|---------|
| `buildMergedGedcom(originalText, exportPersons, exportFields, ftlsFamilyMap, extFamilyIds)` | 1464 | Merge FTLS into external GEDCOM |
| `buildReplacementIndi(p)` | 1547 | Build replacement via `personToGedcomLines` |

**Single path:** For every existing person marked for export:
1. Find their INDI block in the original GEDCOM
2. Extract cardinal features (tags NOT in KNOWN_EXPORT_L1)
3. Build fresh INDI via `personToGedcomLines`
4. Append cardinal features as `_xg`
5. Replace original block

Cardinal features preserved: OBJE, RESI, BURI, _CRE, CHAN, DIV, and any other unknown tags.

---

## GEDCOM Parser (Lines 1602-1960)

| Function | Line | Purpose |
|----------|------|---------|
| `parseGedcomFile(text)` | 1602 | Parse GEDCOM → elements. Handles CONT/CONC, BOM, CR. |
| `getChildValue(el, tag)` | 1656 | Get child tag value |
| `getNestedValue(el, parentTag, childTag)` | 1661 | Get nested tag value |
| `parseIndi(el)` | 1668 | Parse INDI → person object |
| `parseFam(el)` | 1805 | Parse FAM → family object |
| `buildTreeFromFlat(people, families)` | 1828 | BFS tree builder with generation assignment |

---

## Auth System (Lines 2030-2290)

| Function | Line | Purpose |
|----------|------|---------|
| `canEdit()` | 2113 | editor/admin/super_admin |
| `isAdmin()` | 2114 | admin/super_admin |
| `isSuperAdmin()` | 2115 | super_admin only |
| `canEditorDirectEdit(targetId, ...)` | 2121 | Branch permission check |

---

## React Components

| Component | Line | Props |
|-----------|------|-------|
| `PasswordResetForm` | 2294 | token, onDone |
| `LoginModal` | 2353 | onSuccess, onCancel, onRequestAccount |
| `RequestAccountModal` | 2441 | flat, onDone, onCancel |
| `ViewerIdentityModal` | 2561 | submitData, flat, onDone, onCancel |
| `AdminPanel` | 2666 | onClose, onReloadTree, onShowMigrate, onShowDiff, onShowBackfill |
| `EditForm` | 3180 | node, onSave, onCancel, isNew, parentId, parentName |
| `TreeNode` | 3297 | node, exp, onTog, onSel, onEdit, onAdd, onDel, ... |
| `Detail` | 3345 | node, onClose, onEdit, onEditSpouse, onDelSpouse, onMove, root |
| `PhotoGallery` | 3463 | flat, user |
| `MediaUploadModal` | 3609 | flat, user, onDone, onCancel |
| `GedcomDiffModal` | 3752 | onClose, personMap, familyMap, user, onMergeComplete |
| `MoveBranchModal` | 4413 | node, personMap, familyMap, flat, tree, user, ... |
| `BackfillModal` | 4623 | onClose, onComplete |
| `App` | 4999 | (root component) |

---

## GedcomDiffModal Safety Rules (CRITICAL)

1. **Changed persons:** No "All Import". Individual toggle only. "⚠ would clear" warning.
2. **New external persons:** Bulk import ONLY for connected-to-tree persons.
3. **Others:** Read-only. Pass through unchanged.
4. **Export always safe.** Never modifies FTLS database.

---

## Dark Theme Tokens
BG `#0a0805`, TX `#e8e0d4`, GC `#c4a35a`, MC `#a8c9ad`, FC `#b8aed4`, DM `#8a8578`, BR `rgba(196,163,90,0.12)`

---

## Key Data Flows

### GEDCOM Round Trip (lossless)
```
Import: parseIndi() → _extra_gedcom stored in persons table
        parseGedcomFile() handles CONT/CONC joining
Store:  persons._extra_gedcom, gedcom_meta (OBJE/NOTE)
Export: personToGedcomLines() builds INDI, caller appends _xg
        pushNote() splits multi-line text into CONT lines
        downloadGedcom() loads gedcom_meta, inserts before TRLR
```

### Merged Export
```
Load external GEDCOM → parse → diff against FTLS
User marks persons for export → basket computed
batchMergeIntoGedcom() → buildMergedGedcom()
  For new persons: personToGedcomLines() + FAMS/FAMC + _xg
  For existing: extract cardinal from original → personToGedcomLines() + cardinal
  Result: original GEDCOM with FTLS changes patched in
```
