# FTLS Open Source Knowledge Base

## Purpose
Reference document for building FTLS multi-family visualization, relationship calculator, GEDCOM merge improvements, and cluster detection. Instead of reinventing the wheel, we draw algorithms, patterns, and edge-case handling from these proven open-source projects.

---

## 1. TOPOLA — Genealogy Visualization Library (PRIMARY)

**Repo:** https://github.com/PeWu/topola
**Language:** TypeScript/JavaScript
**License:** Apache 2.0
**Why it matters:** Directly compatible with FTLS stack. D3-based SVG rendering. npm installable.

### Key Features to Port
- **Relatives chart** — shows descendants, ancestors, AND descendants of ancestors in one view (the "dual tree" concept)
- **Fancy chart** — aesthetic pedigree visualization
- **GEDCOM parsing** — their parser handles edge cases we've hit
- **Click-to-navigate** — click a person to re-center the chart on them

### Key Source Files
- `src/relatives-chart/` — the multi-directional chart layout algorithm
- `src/fancy-chart/` — the aesthetic rendering
- `src/data/` — GEDCOM parsing and data normalization
- `src/chart.ts` — base chart rendering with D3

### Topola Viewer (Full App)
**Repo:** https://github.com/PeWu/topola-viewer
- Complete web app wrapping the library
- Can be embedded in iframe
- Can be built as standalone with bundled GEDCOM
- Integrates with Webtrees, WikiTree, Gramps

### How to Use in FTLS
- Install via npm: `npm install topola`
- Or reference the source for algorithm patterns
- The chart rendering can be adapted to read from Supabase instead of GEDCOM
- The layout algorithms (how to position nodes for N generations) are the real value

---

## 2. WEBTREES D3 CHART MODULES — SVG Visualizations

### Fan Chart
**Repo:** https://github.com/magicsunday/webtrees-fan-chart
- SVG-based ancestor fan chart
- D3.js rendering
- Configurable generations (up to 10)
- Color coding by generation

### Pedigree Chart
**Repo:** https://github.com/magicsunday/webtrees-pedigree-chart
- SVG pedigree chart — up to 25 generations
- Top-to-bottom and left-to-right layouts
- D3-based rendering
- The layout algorithm handles exponential growth of ancestors

### Descendants Chart
**Repo:** https://github.com/magicsunday/webtrees-descendants-chart
- SVG descendants chart WITH spouses shown
- D3-based rendering
- Handles the spouse display problem we have

### How to Use in FTLS
- These are PHP modules wrapping D3/SVG JavaScript
- Extract the D3 rendering code from `resources/js/` directories
- The SVG generation patterns and layout algorithms are language-agnostic
- The fan chart would be excellent for the "which family cluster am I in?" overview

---

## 3. WEBTREES CORE — Relationship Calculator & GEDCOM Handling

**Repo:** https://github.com/fisharebest/webtrees
**Language:** PHP
**License:** GPL v3

### Key Algorithms to Port

#### Relationship Calculator
**Location:** `app/Relationships/` directory
- BFS-based shortest path between any two individuals
- Handles multiple relationship paths (e.g., "2nd cousin AND brother-in-law")
- Language-specific relationship naming (cousin, uncle, niece, etc.)
- Configurable to search through N generations

#### GEDCOM Parser
**Location:** `app/Gedcom/` directory
- 15+ years of edge-case handling
- Handles malformed GEDCOM, encoding issues, BOM stripping
- The `GedcomRecord` class handles the NAME/TYPE lookahead bug we hit
- Media object (OBJE) handling — relevant to our photo passthrough
- Handles empty DEAT tags (our is_deceased bug)

#### Unconnected Individuals Detection
**Location:** `app/Statistics/` and various chart modules
- Algorithm to find all connected components in the family graph
- Used by the "branches" feature to show families by surname
- The Multi-Treeview module extends this for cluster visualization

#### Privacy/Access Control
**Location:** `app/Auth/` and `app/Privacy/`
- Five-level privacy: none, authenticated, member, manager, administrator
- Per-record privacy settings
- Date-based privacy (hide living individuals automatically)
- Configurable at site, tree, user, record, and fact level
- Maps directly to our five-tier access system

### How to Use in FTLS
- Port the BFS relationship algorithm to JavaScript
- Study the GEDCOM parser for edge cases — use as test case reference
- Adapt the privacy model concepts to our Supabase RLS policies
- The "branches by surname" feature maps to our cluster detection need

---

## 4. VESTA EXTENDED RELATIONSHIPS — Graph Traversal

**Repo:** https://github.com/vesta-webtrees-2-custom-modules/vesta_extended_relationships
**Language:** PHP
**License:** GPL v3

### Key Features
- Extended relationship path calculation
- Common ancestor detection and inclusion in relationship paths
- Handles relationship BEFORE marriage (e.g., "married his brother's wife's sister")
- Date-aware relationships (calculates relative to event dates)
- Multi-path relationship display (shows ALL paths, not just shortest)

### How to Use in FTLS
- The "common ancestor" algorithm is exactly what we need for bridge detection
- The multi-path display helps show how two people from different clusters connect
- Port the graph traversal logic to JavaScript for client-side computation

---

## 5. OTHRAM MAPS — Graph-Powered Genealogy Platform

**URL:** https://maps.othram.com
**Paper:** https://academic.oup.com/bioinformatics/article/42/2/btag047/8440674
**License:** Freely available (web platform)

### Key Features to Study
- **Surname Connector Finder** — analyzes multiple subtrees to identify shared surnames revealing potential relationships between families
- **MRCA Path Builder** — visual pathway connecting multiple individuals to their most recent common ancestors
- **GGPS (Genetic Genealogical Positioning System)** — places unknown persons in the tree based on graph analysis
- **Relationship Calculator** — estimates possible relationships between any two people
- **Load-on-demand engine** — smooth navigation of trees with thousands of individuals

### How to Use in FTLS
- The Surname Connector Finder concept maps directly to our bridge marriage detection
- The MRCA Path Builder is the lineage breadcrumb on steroids
- The load-on-demand pattern solves the "769 people at once" problem
- Study their graph architecture for the cluster map visualization

---

## 6. FAMILY METRO MAPS — Clan-as-Line Visualization

**Paper:** "Interactive Visualization of Genealogical Graphs" (van Wijk et al.)
**Concept:** Each family is a metro line; parents are end nodes, children are intermediate nodes; marriages are line intersections

### How to Use in FTLS
- The cluster overview (Level 1 visualization) could use this metaphor
- Each clan (Chennamkara, Punnose, Oommen, Alexander) is a colored "line"
- Where lines cross = bridge marriages
- Clean, intuitive, non-overwhelming for 8-10 family clusters

---

## 7. LINEAGE — Multi-Family Graph with Aggregation (U of Utah)

**Paper:** https://sci.utah.edu/~vdl/papers/2018_tvcg_lineage.pdf
**Concept:** Linearized tree layout aligned with tabular data view

### Key Innovation: Data-Driven Aggregation
- Three states for any branch: **hidden**, **aggregated**, **expanded**
- Hidden = branch exists but not shown (just a count)
- Aggregated = branch shown as single summary row with stats
- Expanded = full detail
- User controls which branches are in which state

### How to Use in FTLS
- Apply to the multi-family view: start with all branches aggregated
- User expands Chennamkara → sees the tree
- Connected clusters show as aggregated badges
- Click to expand any cluster
- This is the progressive disclosure pattern

---

## 8. FAMILY-CHART — D3-Based Tree Component

**Repo:** https://github.com/donatso/family-chart
**Language:** JavaScript/D3
**License:** MIT

### Key Features
- Clean D3-based family tree rendering
- Handles multiple marriages
- Compact layout algorithm
- Card-based person display

### How to Use in FTLS
- Alternative to Topola for the core tree rendering
- Simpler codebase, may be easier to adapt
- MIT license (more permissive than Topola's Apache)

---

## 9. NEO4J FAMILY TREE — Graph Query Patterns

**Repo:** https://github.com/sylhare/family-tree
**Language:** Python/Cypher
**Concept:** Family data modeled as graph database

### Key Patterns
- Cypher queries for "shortest path between two people"
- Relationship type modeling (PARENT_OF, SPOUSE_OF, CHILD_OF)
- Graph traversal for finding all descendants, all ancestors
- Cycle detection (pedigree collapse / intermarriage)

### How to Use in FTLS
- Port the Cypher query patterns to Supabase SQL recursive CTEs
- The relationship modeling patterns inform our schema design
- We already use recursive CTEs for tree walking — this extends them

---

## 10. MCGUFFIN DUAL TREE — Academic Foundation

**Paper:** "Interactive Visualization of Genealogical Graphs" (IEEE InfoVis 2005)
**Authors:** Michael J. McGuffin, Ravin Balakrishnan

### Key Concepts
- **Dual Tree:** Shows ancestors of person X AND descendants of ancestor Y simultaneously
- **Multitree:** When two trees of descendants share subtrees (intermarriage)
- **Fractal layout:** Can theoretically show infinite generations
- The exponential growth problem: N generations = 2^N ancestors but only linear screen space

### How to Use in FTLS
- The dual tree concept is perfect for the person-centric view
- Click any person → see their ancestors going up, their descendants going down
- The multitree handling solves the intermarriage/pedigree collapse case
- Informs the "hourglass" view option

---

## 11. WEBTREES INTERACTIVE TREEVIEW (EXTENDED)

**Topic:** https://github.com/topics/webtrees-module
- Extended version with: export to PNG, collapsible subtrees, stepwise expanding
- Scrollable viewport with generation count control (1-25)
- Handles implex (pedigree collapse)
- Pagemap for orientation in large trees

### How to Use in FTLS
- The collapsible subtrees pattern for the multi-family view
- The pagemap concept (mini-map showing where you are in the big tree)
- The implex handling for families with intermarriage

---

## 12. GENI WORLD FAMILY TREE — Merge & Stitch Concepts

**URL:** https://www.geni.com
**Concept:** Stitching overlapping family trees from different users

### Key Concepts
- **Tree Match:** Detects when two users have overlapping tree data
- **Profile Merge:** Combines duplicate profiles into one
- **Curator System:** Volunteer experts who resolve conflicts
- **Multi-language profiles:** Names in multiple languages/scripts

### How to Use in FTLS
- The Tree Match concept is exactly our diff tool
- The merge conflict resolution patterns inform our import safety
- The curator concept maps to our admin approval queue

---

## Build Priority for FTLS

### Phase 1 (Next Session): Cluster Detection & Selector
- Use webtrees' unconnected-individuals algorithm
- Auto-detect family clusters from graph structure
- Build `family_clusters` and `person_clusters` tables
- Add cluster dropdown to existing tree view

### Phase 2: Multi-Family Visualization
- Integrate Topola library for the per-cluster tree view
- Build Level 1 cluster map (force-directed, D3)
- Implement Lineage's aggregation (hidden/aggregated/expanded)

### Phase 3: Relationship Calculator
- Port Vesta Extended Relationships' BFS algorithm
- Build "how is A related to B?" feature
- Bridge detection using Othram Maps' Surname Connector pattern

### Phase 4: Enhanced GEDCOM Merge
- Study webtrees' GEDCOM parser for edge cases
- Implement Geni's Tree Match concepts
- Add the "would-clear" protection we already built to field level

### Phase 5: Permissions by Cluster
- Adapt webtrees' five-level privacy model
- Implement cluster-scoped editing (Abey edits Punnose branch, Rolson edits Chennamkara)
- Super admin sees all
