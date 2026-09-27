# Ashadee Quest Ledger

A private live dashboard for the `quest_rewards_ashadee` table in the **GC Quest Reward Tracker** Supabase project (Grundo's Data org).

## What is here

| File | What it is |
| --- | --- |
| `dashboard.html` | The published dashboard, with the queries and five quest giver pictures embedded. |
| `sql/q_summary.sql` | Totals, per-quest neopoints, daily counts, stat boosts. |
| `sql/q_rewards.sql` | Relics, faeries, snowballs, coupons, codestones and top rewards, matched to `items`. |
| `sql/q_requested.sql` | Most requested items with rarity. |
| `data/items_clean.csv` | The item list (6,376 rows) loaded into the `items` table. |

## How it works

The page runs inside a Claude artifact. It calls the Supabase connector's `execute_sql` tool as the viewer, so it only works while signed in to Claude with the Supabase connector allowed. It does not work as a normal website, and no database key is stored in these files.

Item pictures are not shown because artifact pages cannot load images from other sites.

## Rebuild the `items` table

```sql
create table if not exists public.items (
  id bigint generated always as identity primary key,
  name text not null,
  image_url text,
  rarity integer,
  category text not null default 'item'
);
create unique index if not exists items_name_key on public.items (lower(btrim(name)));
create index if not exists items_category_idx on public.items (category);
alter table public.items enable row level security;
```

Then import `data/items_clean.csv` with Supabase Table Editor, Insert, Import data from CSV.
