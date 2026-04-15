# FTLS Multi-Family Network — Design & Roadmap

## The Problem
FTLS has 769 persons but only 488 are reachable from the Chennamkara root (Mathan Mathai). The remaining 281 are extended in-law families connected through marriages. These are real family — Abey's and Rolson's relatives — but the current single-root tree can't show them.

## The Vision
Transform FTLS from a single-family tree into a **family network platform** where multiple clans can independently manage their branches while seeing how they interconnect through marriages.

## Graph Theory Foundation

### The Data Structure
- **Nodes** = 769 persons
- **Directed edges** = parent → child links
- **Undirected edges** = spouse links (marriages)
- **Connected components** (following only parent-child) = multiple separate trees (a "forest")
- **Bridge edges** = marriages connecting separate components

### Key Concept: Bridge Marriages
When you remove all spouse edges and only follow parent-child links, the graph breaks into ~10 separate trees. The marriages that re-connect these trees are the **bridge marriages** — structurally the most important connections in the family network.

### Known Bridges
1. T O Jacob ⚭ Joy Jacob — connects Punnose/Oommen (largest in-law clan, ~200 people) to Chennamkara
2. Aleyamma Abraham ⚭ George Chennamkara Abraham — Oommen to Chennamkara
3. Sheeba Abraham ⚭ Rolson Chennamkara Abraham — Alexander to Chennamkara
4. Arun Kumar Samuel ⚭ Rincy Samuel — Kumar to Chennamkara

## Three-Level Visualization Design

### Level 1: Cluster Map (the "country view")
**What:** Each family clan is a node (circle/badge with name + member count). Bridge marriages are lines connecting circles.
**Purpose:** "How are these families related to each other?"
**Implementation:** D3 force-directed graph layout. Nodes repel, edges attract. Related families cluster naturally.
**Interaction:** Click a clan node → drill down to Level 2.

```
  [Punnose (14)] ——— [Oommen (12)]
        |                  |    \
  [Mathai (6)]    [Chacko (8)]  [Alexander (7)]
        |                          |
  [Chennamkara (348)] ————————————+
        |
  [Varghese (15)]  [Thomas (10)]  [Koshy (12)]
```

### Level 2: Family Tree View (the "city view")
**What:** Pedigree tree for a single clan. Spouses that bridge to other clans get colored badges.
**Purpose:** "Show me this family's tree."
**Implementation:** D3 tree layout (adapt Topola patterns). Click bridge spouse badge → switch to that clan.
**Key feature:** Lineage's aggregation states — hidden/aggregated/expanded for branches.

### Level 3: Person Detail (the "street view")
**What:** Existing person card/panel.
**Enhancement:** Show dual lineage (blood lineage + in-law connection). Mini-map showing position in cluster network.

## Data Model Changes

### New Tables

```sql
-- Family clusters (auto-detected, admin-editable)
CREATE TABLE family_clusters (
  id text PRIMARY KEY,
  name text NOT NULL,           -- "Chennamkara", "Punnose", "Oommen"
  root_person_id text,          -- patriarch of this clan
  color text,                   -- hex color for visualization
  owner_email text,             -- cluster admin
  member_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Person-to-cluster mapping
CREATE TABLE person_clusters (
  person_id text REFERENCES persons(id),
  cluster_id text REFERENCES family_clusters(id),
  is_bridge boolean DEFAULT false,   -- person's marriage connects two clusters
  bridge_to_cluster text,            -- which other cluster they connect to
  PRIMARY KEY (person_id, cluster_id)
);
```

### Cluster Auto-Detection Algorithm
1. Remove all spouse edges — only keep parent-child links
2. Run connected components algorithm (BFS from each unvisited node)
3. Each component is a cluster — name it by the root's surname
4. Find bridge marriages: for each family, if husband's cluster ≠ wife's cluster, both are bridges
5. Count members per cluster
6. Store in tables

## Permission Model Extension

### Current: Single tree, single permission set
### Future: Per-cluster permissions

```
family_cluster_roles:
  cluster_id text
  user_email text
  role text ('owner', 'editor', 'viewer')
```

- **Cluster Owner** = can edit anyone in their cluster (Rolson for Chennamkara, Abey for Punnose/Oommen)
- **Cluster Editor** = can edit own branch within cluster
- **Cross-cluster** = everyone can SEE connected clusters, can only EDIT within own
- **Super Admin** = Steve, sees/edits everything

## Progressive Disclosure Principle
Never show 769 people at once. Instead:
1. Start with cluster map (~10 nodes)
2. User picks a cluster → see 50-100 people in tree
3. Connected clusters shown as collapsed badges on spouse nodes
4. Click badge → hop to next cluster
5. Always know where you are via breadcrumb: "Chennamkara > Soman's branch > Steve"

## Open Source Resources (see FTLS_Open_Source_Knowledge_Base.md)
- **Topola** — D3 tree rendering, npm library
- **Webtrees D3 modules** — fan chart, pedigree chart, descendants chart
- **Vesta Extended Relationships** — graph traversal, relationship calculator
- **Othram Maps** — Surname Connector Finder for bridge detection
- **Lineage** — aggregation (hidden/aggregated/expanded) for scaling
- **Family Metro Maps** — clan-as-metro-line concept for cluster overview
- **McGuffin Dual Tree** — academic foundation for multi-root visualization

## Build Phases

### Phase 1: Cluster Detection & Basic Selector
- Auto-detect clusters from existing 769-person graph
- Create family_clusters and person_clusters tables
- Populate via SQL
- Add "Viewing: [cluster name]" dropdown to existing tree view
- Filter tree rendering to show only selected cluster(s)

### Phase 2: Cluster Map (Level 1)
- D3 force-directed graph showing clusters as nodes
- Bridge marriages as labeled edges
- Click node → switch to that cluster's tree
- Show member counts, root ancestor name

### Phase 3: Relationship Calculator
- "How is person A related to person B?"
- BFS shortest path through the family graph
- Show the path: A → parent → grandparent → ... → common ancestor → ... → B
- Handle multi-path relationships

### Phase 4: Enhanced Bridge View
- When viewing a cluster, highlight bridge spouses with colored badges
- Click badge → hop to connected cluster
- Show mini-map of cluster network in corner

### Phase 5: Cluster Permissions
- Per-cluster owner assignment
- Editing scoped to own cluster
- Cross-cluster read access for all authenticated users
- Super admin override

## Key Design Decisions Made
- ✅ Swim-lane visualization rejected — pedigree tree preferred
- ✅ Progressive disclosure — never show all 769 at once
- ✅ Cluster detection is automatic but admin-editable
- ✅ Bridge marriages are the primary inter-cluster connections
- ✅ Each clan can have its own admin
- ✅ Export always safe, import requires per-person review for existing records
- ✅ Others (unconnected to any root) are read-only in diff tool
