-- FTLS v4.7.10: add primary_family_id to persons
-- UI preference column. Null = date-based fallback. Does not export to GEDCOM.
alter table persons
  add column if not exists primary_family_id text;

-- Partial index for faster lookups on the few rows that have it set.
create index if not exists persons_primary_family_id_idx
  on persons (primary_family_id)
  where primary_family_id is not null;;
