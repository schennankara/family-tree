# FTLS index.html — Code Structure & Function Reference

**File:** `index.html` (single-file React app, ~5750 lines)
**Version:** v4.7.0
**Stack:** React 18 via CDN, Babel transpiler, Supabase JS client
**Live:** https://schennankara.github.io/family-tree/

---

## File Layout Overview

```
Lines 1-42       HTML head, CDN imports (React, Babel, Supabase, Cloudinary)
Lines 43-66      Environment config (Supabase URL, anon key, Cloudinary)
Lines 67-130     Utility functions (image resize, Cloudinary upload, media)
Lines 131-275    Supabase data layer (load, build tree, save person)
Lines 274-500    CRUD operations (save, delete, add person, spouse, move branch)
Lines 543-720    GEDCOM migration (parse GEDCOM → write to Supabase)
Lines 724-812    MigrateDialog component
Lines 813-1090   GEDCOM full export (exportTreeToGedcom, downloadGedcom)
Lines 1091-1270  Diff engine (diffPerson, fuzzyMatch, computeGedcomDiff)
Lines 1270-1500  Merge operations (mergePersonToDb, mergeFieldsToDb)
Lines 1501-1720  Merged GEDCOM export (buildMergedGedcom)
Lines 1724-2068  GEDCOM parser (parseGedcomFile, parseIndi, parseFam, buildTreeFromFlat)
Lines 2069-2138  Import GEDCOM trigger function
Lines 2139-2400  Auth system (persistAuth, getHeaders, canEdit, role checks, branch permissions)
Lines 2406-2780  Auth UI components (PasswordReset, Login, RequestAccount, ViewerIdentity)
Lines 2778-3290  AdminPanel component (user management, edit log, approval queue, settings)
Lines 3292-3408  EditForm component (person editing form)
Lines 3409-3456  TreeNode component (single tree node rendering)
Lines 3457-3574  Detail component (person detail side panel)
Lines 3575-3720  PhotoGallery component
Lines 3721-3863  MediaUploadModal component
Lines 3864-4524  GedcomDiffModal component (the diff & merge tool)
Lines 4525-4734  MoveBranchModal component
Lines 4735-5110  BackfillModal component (GEDCOM extras backfill tool)
Lines 5111-5753  App component (main application, routing, state management)
```

---

## SECTION 1: Utilities & Configuration (Lines 43-130)

### Environment
- `SB_URL` — Supabase project URL
- `SB_KEY` — Supabase anon key (public, safe in frontend)
- `CLOUD_NAME`, `UPLOAD_PRESET` — Cloudinary config

### Functions
| Function | Line | Purpose |
|----------|------|---------|
| `cldImg(url, transforms)` | 67 | Apply Cloudinary transformations to image URL |
| `resizeImage(file, maxSize)` | 73 | Client-side image resize before upload |
| `uploadToCloudinary(file, folder)` | 91 | Upload image/PDF to Cloudinary |
| `saveMediaRecord(record)` | 110 | Save media metadata to Supabase `media` table |
| `loadMedia(personId)` | 118 | Load all media for a person |
| `sbFetch(path, opts)` | 125 | Authenticated Supabase REST fetch wrapper with auto-retry on 401 |

---

## SECTION 2: Supabase Data Layer (Lines 167-275)

### Functions
| Function | Line | Purpose |
|----------|------|---------|
| `loadFromSupabase()` | 167 | Load all persons + families from Supabase. Returns `{persons, families}` |
| `buildTreeFromDB(persons, families)` | 184 | Convert flat DB rows into hierarchical tree. Loads `_extra_gedcom`, `title_prefix`, `burial_date`. Selects root (skips unnamed). Returns `{tree, flat, personMap, familyMap}` |
| `countDesc(pid)` | 218 | Count descendants of a person (used for root selection) |
| `buildNode(pid, visited)` | 244 | Recursive node builder — creates tree node with children, spouse, generations |

### Tree Node Shape
```javascript
{
  id, fn, mn, ln, dn, nk, md, g,     // name fields, gender
  dob, dod, dec,                       // dates, deceased
  em, ph, a1, a2, ci, st, zp, co,    // contact/address
  fb, ig, li, ws,                      // social
  pp, bio, loc, prof, emp,            // profile
  stories, notes, pgl, dl, bo,        // content
  tp, burd, _xg,                       // GEDCOM extras
  gen, spouse, children, _raw          // tree structure
}
```

---

## SECTION 3: CRUD Operations (Lines 274-540)

| Function | Line | Purpose |
|----------|------|---------|
| `savePerson(person, editUser)` | 274 | Upsert person to Supabase. Logs changes to `edit_log` with previous values. Includes `_extra_gedcom`, `title_prefix`, `burial_date`. |
| `saveFamily(familyId, husbandId, wifeId, children, mdate, mplace)` | 359 | Upsert family record |
| `deletePersonFromDB(personId, editUser)` | 373 | Delete person + remove from families. Logs to edit_log. Cleans up empty families. |
| `addPersonToDB(person, parentId, editUser)` | 402 | Add new person + create/update family link. Smart family selection (finds existing incomplete family or creates new one). |
| `saveSpouseToDB(parentId, spouse, editUser)` | 443 | Add spouse to existing person. Finds incomplete family or creates new one. |
| `deleteSpouseFromDB(parentId, spouseId, editUser)` | 467 | Remove spouse from family (nullifies slot, doesn't delete person) |
| `movePersonBranch(personId, fromFamilyId, toFamilyId, editUser)` | 480 | Move person from one parent family to another. Updates children arrays. |

---

## SECTION 4: GEDCOM Migration (Lines 543-723)

| Function | Line | Purpose |
|----------|------|---------|
| `loadSourceGedcom()` | 543 | Fetch GEDCOM from GitHub repo (fallback source) |
| `migrateGedcomToSupabase(gedcomText, onProgress)` | 556 | Full GEDCOM → Supabase migration. Parses INDI/FAM records, handles NAME/TYPE bug, BOM stripping, empty DEAT tags. ⚠️ Destructive — replaces all DB data. |

### MigrateDialog Component (Line 724)
- Props: `{onDone, onCancel}`
- File upload or "From Repository" button
- Progress display during migration
- **Admin only** — the "Migrate GEDCOM→DB" button in admin panel

---

## SECTION 5: GEDCOM Export (Lines 813-1090)

| Function | Line | Purpose |
|----------|------|---------|
| `exportTreeToGedcom(tree, personMap, familyMap)` | 813 | Full tree → GEDCOM string. Walks tree recursively. Appends `_extra_gedcom` lines per person. |
| `downloadGedcom(tree, personMap, familyMap)` | 1050 | **Async.** Loads `gedcom_meta` (OBJE/NOTE records), calls `exportTreeToGedcom`, appends OBJE/NOTE before TRLR, triggers file download. |

### Internal helpers in exportTreeToGedcom:
- `buildIndi(person)` (line 848) — Build GEDCOM INDI record from person object. Handles NAME, SEX, BIRT, DEAT, RESI, ADDR, OBJE refs, FAMC/FAMS, and `_xg` passthrough.
- `buildFam(fam)` (line 944) — Build GEDCOM FAM record.
- `processNode(node, parentFamId)` (line 979) — Recursive tree walker for export.

---

## SECTION 6: Diff Engine (Lines 1091-1270)

| Function | Line | Purpose |
|----------|------|---------|
| `diffPerson(ftls, ext)` | 1091 | Compare FTLS person vs external person. Returns array of `{key, label, ftls, ext}` diffs. Compares: name, gender, DOB, DOD, deceased, address, contact, notes, profession. |
| `fuzzyMatchPerson(person, candidates)` | 1111 | Score-based fuzzy matching by name+DOB. Returns best match if score > threshold. Used to match persons with different IDs. |
| `computeGedcomDiff(extPeople, extFamilies, ftlsPersonMap, ftlsFamilyMap)` | 1141 | **Main diff algorithm.** Returns `{matched, extOnly, ftlsOnly, fuzzyMatched, familyDiffs, stats}`. Matches by ID first, then fuzzy. Computes family-level diffs (FTLS-only families, ext-only families). |

---

## SECTION 7: Merge Operations (Lines 1270-1500)

| Function | Line | Purpose |
|----------|------|---------|
| `mergePersonToDb(ext, editUser)` | 1270 | Import external person into Supabase (new person). Creates person record + updates family links. |
| `mergeFamilyToDb(extFam)` | 1288 | Import external family. Creates or updates family record, merges children arrays without duplicates. |
| `mergeFieldsToDb(ftlsPerson, fieldsToApply, ext, editUser)` | 1327 | Import specific fields from external person into existing FTLS person. Field-level granularity. Logs to edit_log. |
| `exportDiffGedcom(persons, ftlsFamilyMap, extFamilyIds, extFamiliesMap)` | 1357 | Generate fragment GEDCOM containing only the selected diff persons + their families. Includes `_extra_gedcom` passthrough and `gedcom_meta` OBJE/NOTE records. |
| `buildMergedGedcom(originalText, exportPersons, exportFields, ftlsFamilyMap, extFamilyIds)` | 1501 | Merge FTLS changes INTO the original external GEDCOM. Replaces existing INDI blocks with FTLS data, adds new persons, patches individual fields. Preserves unknown GEDCOM tags from original. |

### Internal helper in buildMergedGedcom:
- `buildReplacementIndi(p)` (line 1592) — Build replacement INDI block for merged export. If person has `_xg`, appends it. If not, extracts unknown tags from original INDI block.

---

## SECTION 8: GEDCOM Parser (Lines 1724-2068)

| Function | Line | Purpose |
|----------|------|---------|
| `parseGedcomFile(text)` | 1724 | Parse raw GEDCOM text into structured elements. BOM stripping, CR normalization. Returns `{elements}` array of level/tag/value/children. |
| `getChildValue(el, tag)` | 1768 | Get value of first child with given tag |
| `getNestedValue(el, parentTag, childTag)` | 1773 | Get value of nested child (e.g., BIRT > DATE) |
| `parseIndi(el)` | 1780 | Parse INDI element into person object. Handles NAME/TYPE scoping, multiple names (nick, birth, married), RESI/ADDR address parsing, OBJE, NOTE, BURI, CHAN, _CRE. |
| `parseFam(el)` | 1917 | Parse FAM element into family object |
| `parseDateSort(d)` | 1928 | Convert date string to sortable number |
| `buildTreeFromFlat(people, families)` | 1940 | BFS-based tree builder from flat person/family arrays. Generation assignment with spouse/child fallback. Selects root by largest descendant count. |
| `triggerImportGedcom(onImport)` | 2069 | File picker → parse → build tree → callback |

---

## SECTION 9: Auth System (Lines 2139-2400)

### Global Auth State
- `authUser` — current logged-in user object (email, role, person_id)
- `gatePassword` — viewer gate password from settings

| Function | Line | Purpose |
|----------|------|---------|
| `persistAuth()` | 2139 | Restore auth from localStorage on page load |
| `getHeaders()` | 2219 | Build Supabase auth headers (Bearer token) |
| `canEdit()` | 2225 | Returns true if user is editor, admin, or super_admin |
| `isAdmin()` | 2226 | Returns true if admin or super_admin |
| `isSuperAdmin()` | 2227 | Returns true if super_admin only |
| `isEditor()` | 2228 | Returns true if editor only |
| `canEditorDirectEdit(targetId, tree, pMap, fMap)` | 2233 | Check if editor can directly edit a specific person (must be in their branch). Walks tree to verify. |
| `canEditorDirectEditTreeFallback(targetId, tree)` | 2348 | Fallback branch check using tree structure |
| `findNodeInTree(node, id)` | 2359 | Find node by ID in tree hierarchy |
| `findFamilyNodeContaining(node, personId)` | 2370 | Find family node containing a person |
| `findParentOf(node, childId)` | 2380 | Find parent node of a child |
| `findParentFamilyOf(node, personId)` | 2390 | Find the family a person belongs to as child |
| `isDescendant(node, targetId)` | 2394 | Check if targetId is a descendant of node |

---

## SECTION 10: Auth UI Components (Lines 2406-2780)

### PasswordResetForm (Line 2406)
- Props: `{token, onDone}`
- Shown when user clicks password reset link from email

### LoginModal (Line 2465)
- Props: `{onSuccess, onCancel, onRequestAccount}`
- Email/password login
- "Forgot password" flow
- Admin and family member login

### RequestAccountModal (Line 2553)
- Props: `{flat, onDone, onCancel}`
- New user registration
- Links to existing person in tree
- Sends request to admin for approval

### ViewerIdentityModal (Line 2673)
- Props: `{submitData, flat, onDone, onCancel}`
- For viewers submitting edit requests
- Must identify which person they are

---

## SECTION 11: AdminPanel Component (Lines 2778-3290)

- Props: `{onClose, onReloadTree, onShowMigrate, onShowDiff, onShowBackfill}`
- **Tabs:** Users, Edit Log, Pending Requests, Settings

### Sub-features:
- User management (assign roles, approve/reject accounts)
- Edit log viewer (expandable entries, shows changed_fields vs previous_values)
- Pending edit requests from family members (approve/reject with reason)
- Settings management (viewer gate password, etc.)
- Buttons for: "Migrate GEDCOM→DB", "📦 Backfill GEDCOM Extras", "🔀 Diff & Merge"

---

## SECTION 12: Core UI Components (Lines 3292-3575)

### EditForm (Line 3292)
- Props: `{node, onSave, onCancel, isNew, parentId, parentName}`
- Full person editing form
- Fields: name, gender, DOB, DOD, contact, address (structured), social, bio, profession
- Country dropdown (curated list)
- New person vs edit existing modes

### TreeNode (Line 3409)
- Props: `{node, exp, onTog, onSel, onEdit, onAdd, onDel, onEditSpouse, onDelSpouse, hl}`
- Renders single person node in tree (square=male, circle=female)
- Expandable/collapsible children
- Action buttons (edit, add child, delete)
- Spouse display
- Highlight support for search

### Detail (Line 3457)
- Props: `{node, onClose, onEdit, onEditSpouse, onDelSpouse, onMove, root}`
- Side panel showing person details
- Profile photo, name, dates, contact info, social links
- Action buttons based on user role
- "Move Branch" button for admins

---

## SECTION 13: Photo Gallery (Lines 3575-3863)

### PhotoGallery (Line 3575)
- Props: `{flat, user}`
- Grid display of all uploaded media
- Filter by person
- Lightbox view
- Upload button (opens MediaUploadModal)

### MediaUploadModal (Line 3721)
- Props: `{flat, user, onDone, onCancel}`
- Upload photos/documents to Cloudinary
- Tag persons in photos
- Caption and date fields

---

## SECTION 14: GedcomDiffModal — The Diff & Merge Tool (Lines 3864-4524)

**This is the largest and most complex component (~660 lines).**

### Props
`{onClose, personMap, familyMap, user, onMergeComplete}`

### State
| State | Purpose |
|-------|---------|
| `diffResult` | Output of `computeGedcomDiff()` — all matched/unmatched persons and families |
| `extGedcomText` | Raw external GEDCOM text (kept for merge-into) |
| `extFamilyIds` | Set of family IDs from external GEDCOM |
| `extFamiliesMap` | Parsed external families (for child comparison, connection detection) |
| `extPeopleMap` | Parsed external persons (for breadcrumbs) |
| `tab` | Active tab: summary, changed, ext_only, ftls_only, fuzzy, basket |
| `expandedDiffs` | Set of person IDs with expanded field-level diffs |
| `extDir` | `{personId: 'import'}` — direction for external-only persons |
| `ftlsDir` | `{personId: 'export'}` — direction for FTLS-only persons |
| `changedDir` | `{personId: 'import'|'export'}` — direction for changed persons |
| `fieldDir` | `{personId: {fieldKey: 'import'|'export'}}` — per-field direction overrides |
| `extFamDir` | `{familyId: 'import'}` — direction for external-only families |
| `showAddrOnly` | Toggle: show address-only diffs in Changed tab |
| `showOthers` | Toggle: expand Others section in Changed tab |

### Key Inner Functions
| Function | Line | Purpose |
|----------|------|---------|
| `handleFile()` | 3890 | File picker → parse GEDCOM → compute diff |
| `toggleExpand(id)` | 3933 | Toggle expanded state for a person's diffs |
| `setPersonDirection(id, dir)` | 3943 | Set import/export direction for a person. Cascades to all fields. |
| `setFieldDirection(id, key, dir)` | 3950 | Override direction for a specific field |
| `getFieldDirection(id, key)` | 3957 | Get effective direction for a field (field override > person direction) |
| `ftlsBreadcrumb(personId)` | 3960 | Build ancestor chain from FTLS data (walks up through parent families) |
| `extBreadcrumb(personId)` | 3993 | Build ancestor chain from external GEDCOM data |
| `FamilyPath({personId, showExt, showFtls})` | 4023 | Component: renders lineage breadcrumb (FTLS path, EXT path, ⚠ Different lineage warning) |
| `globalChangedDir(dir)` | 4038 | Set direction for all changed persons at once (only 'export' and null allowed — no bulk import) |
| `basket` (useMemo) | 4047 | Computes import/export baskets from all direction states |
| `batchImport()` | 4077 | Execute all imports in basket (merge persons, merge fields to DB) |
| `batchExportGedcom()` | 4106 | **Async.** Export selected items as fragment GEDCOM file |
| `batchMergeIntoGedcom()` | 4124 | Merge selected FTLS data back into the original external GEDCOM |

### Tab Structure
| Tab | Content |
|-----|---------|
| `summary` | Overview stats: identical, changed, ext-only, ftls-only, fuzzy matches |
| `changed` | **Family Members with Changes** (individual import, bulk export) + **Others** (read-only, collapsed) |
| `ext_only` | External-only persons with bulk import controls |
| `ftls_only` | FTLS-only persons with bulk export controls |
| `fuzzy` | Fuzzy-matched persons (same name/DOB, different IDs) |
| `basket` | Review basket: all items marked for import/export. Execute buttons. |

### Safety Rules (CRITICAL)
1. **Changed persons:** No "All Import" button. Individual toggle only. Prevents mass data wipe (Abey incident 2026-04-13).
2. **"⚠ would clear" warning:** Shown when importing would replace non-empty FTLS data with empty external data.
3. **New external persons:** Bulk import allowed ONLY for persons connected to tree (parent/spouse/child in personMap).
4. **Others:** Read-only. No import/export buttons. Pass through unchanged in merged exports.
5. **Export always safe:** Never modifies FTLS database.

---

## SECTION 15: MoveBranchModal (Lines 4525-4734)

- Props: `{node, personMap, familyMap, flat, tree, user, onMove, onRequestMove, onClose}`
- Search for target parent
- Shows target's families
- Validates move (can't move to own descendant)
- Admin: direct move. Editor/member: request move.

---

## SECTION 16: BackfillModal (Lines 4735-5110)

- Props: `{onClose, onComplete}`
- **Admin tool:** Parse GEDCOM file, match by ID to existing DB records, fill empty fields only.
- Parses: OBJE photo refs, NOTE records, RESI addresses, NAME/TYPE title prefixes, BURI dates, OCCU professions, _extra_gedcom passthrough lines.
- **Never overwrites:** Only fills fields that are currently empty in the DB.
- Preview before applying.
- Also populates `gedcom_meta` table with standalone OBJE and NOTE records.

---

## SECTION 17: App Component — Main Application (Lines 5111-5753)

### State
| State | Purpose |
|-------|---------|
| `tree` | Hierarchical tree structure (root node) |
| `flat` | Flat array of all persons |
| `personMap` | `{id: personObject}` lookup |
| `familyMap` | `{id: familyObject}` lookup |
| `user` | Current authenticated user |
| `selectedNode` | Currently selected person (for detail panel) |
| `editNode` | Person being edited (opens EditForm) |
| `searchTerm` | Search bar value |
| `expandedNodes` | Set of expanded tree node IDs |
| Various modal states | showAdmin, showMigrate, showDiff, showBackfill, showPhotoGallery, showMoveBranch, etc. |

### Key Functions
| Function | Line | Purpose |
|----------|------|---------|
| `reloadTree()` | 5244 | Reload all data from Supabase, rebuild tree |
| `requireAuth(action)` | 5195 | Wrapper: ensure user is authenticated before action |
| `handleLoginSuccess(u)` | 5206 | Post-login: set user, reload tree |
| `handleSignOut()` | 5217 | Sign out, clear state |
| `handleViewerGate()` | 5226 | Verify family password for viewer access |
| `isViewer()` | 5348 | Check if current user is viewer role |
| `needsApproval(targetPersonId)` | 5350 | Check if edit needs admin approval (non-admin editing non-self) |
| `openEditForNode(node)` | 5358 | Open edit form, snapshot before-state for edit_log |
| `handleMove()` | 5483 | Execute branch move |
| `handleRequestMove()` | 5501 | Submit move request for admin approval |

### Render Structure
```
App
├── (Password Reset screen — if reset token in URL)
├── (Viewer Gate — if no auth)
├── (Login / Register modals)
├── Header (logo, search bar, photo gallery button, admin button)
├── Tree View
│   └── TreeNode (recursive)
├── Detail Panel (side panel when person selected)
├── EditForm (modal when editing)
├── AdminPanel (modal)
├── MigrateDialog (modal)
├── GedcomDiffModal (modal)
├── BackfillModal (modal)
├── MoveBranchModal (modal)
├── PhotoGallery (modal)
└── MediaUploadModal (modal)
```

---

## Dark Theme Tokens
| Token | Value | Usage |
|-------|-------|-------|
| BG | `#0a0805` | Page background |
| TX | `#e8e0d4` | Primary text |
| GC | `#c4a35a` | Gold accent |
| GD | `rgba(196,163,90,0.2)` | Gold dividers |
| DM | `#8a8578` | Dim/secondary text |
| MC | `#a8c9ad` | Male color |
| FC | `#b8aed4` | Female color |
| BR | `rgba(196,163,90,0.12)` | Borders |

---

## Key Data Flow

### Loading
```
Page load → persistAuth() → loadFromSupabase() → buildTreeFromDB() → render tree
```

### Editing a Person
```
Click edit → openEditForNode() → snapshot old values → EditForm modal
→ Save → savePerson() → edit_log entry → reloadTree()
```

### Diff & Merge
```
Upload GEDCOM → parseGedcomFile() → computeGedcomDiff() → show tabs
→ User sets directions → basket computed → batchImport() / batchExportGedcom() / batchMergeIntoGedcom()
```

### GEDCOM Round Trip (lossless)
```
Import: parseIndi() extracts _extra_gedcom (OBJE, RESI, BURI, CHAN, _CRE lines)
Store: persons._extra_gedcom column
Export: buildIndi() appends _xg lines back into GEDCOM
        downloadGedcom() loads gedcom_meta → inserts OBJE/NOTE before TRLR
```
