# Ashadee Quest Ledger

Quest reward stats for the `quest_rewards_ashadee` table in the **GC Quest Reward Tracker** Supabase project (Grundo's Data org). There are two versions of the dashboard.

## What is here

| File | What it is |
| --- | --- |
| `index.html` | The public version, served by GitHub Pages. Shows item thumbnails. |
| `dashboard.html` | The private version. Runs inside a Claude artifact through the Supabase connector. No item thumbnails. |
| `sql/functions.sql` | The three aggregate-only functions `index.html` calls. Already applied to Supabase. |
| `sql/q_*.sql` | The queries `dashboard.html` runs through the connector. |
| `data/items_clean.csv` | The item list (6,376 rows) loaded into the `items` table. |

## How the public version works

`index.html` calls three Supabase functions over the REST API using the project's publishable key:

- `dashboard_summary()`
- `dashboard_rewards()`
- `dashboard_requested()`

Each function returns totals and rankings only. They never return raw rows or usernames. The tables themselves stay locked by row level security, so the publishable key in `index.html` cannot read them.

Anyone with the page link can see the totals, top rewards, relic counts and most requested items.

## Turn on GitHub Pages

1. Make the repository public.
2. Open Settings, then Pages.
3. Under Source choose Deploy from a branch, then `main` and `/ (root)`, then Save.
4. The site appears at `https://ashlyleh.github.io/ashadee-quest-ledger/` after a minute or two.

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
