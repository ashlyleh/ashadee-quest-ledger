-- Aggregate-only functions for the public dashboard. They return totals and rankings, never raw rows or usernames.

create or replace function public.dashboard_summary()
returns json
language sql
stable
security definer
set search_path = public
as $fn$
select json_build_object(
  '_k', 'summary',
  'total', count(*),
  'first', min(submitted_at),
  'last', max(submitted_at),
  'last24', count(*) filter (where submitted_at > now() - interval '24 hours'),
  'avg_np', round(avg(neopoints)),
  'total_np', sum(neopoints),
  'quests', (select coalesce(json_agg(q), '[]'::json) from (
      select quest, count(*) as records, min(neopoints) as min_np, max(neopoints) as max_np,
             round(avg(neopoints), 2) as avg_np, sum(neopoints) as total_np,
             count(*) filter (where neopoints is null) as no_np
      from public.quest_rewards_ashadee group by quest) q),
  'daily', (select coalesce(json_agg(d), '[]'::json) from (
      select ((submitted_at at time zone 'America/Chicago')::date)::text as day, count(*) as n
      from public.quest_rewards_ashadee where submitted_at > now() - interval '40 days'
      group by 1 order by 1) d),
  'stats', (select coalesce(json_agg(s), '[]'::json) from (
      select quest, stat_boost as name, count(*) as n
      from public.quest_rewards_ashadee
      where stat_boost is not null and btrim(stat_boost) <> ''
      group by quest, stat_boost order by n desc) s)
) as d
from public.quest_rewards_ashadee
$fn$;

revoke all on function public.dashboard_summary() from public;
grant execute on function public.dashboard_summary() to anon, authenticated, service_role;

create or replace function public.dashboard_rewards()
returns json
language sql
stable
security definer
set search_path = public
as $fn$
with r as (
  select quest, unnest(array[item1, item2, item3]) as nm from public.quest_rewards_ashadee
),
j as (
  select r.quest,
         coalesce(i.name, btrim(r.nm)) as nm,
         coalesce(i.category, case when lower(btrim(r.nm)) = 'codestones' then 'Codestones' else 'Unlisted' end) as cat,
         i.rarity,
         i.image_url as img
  from r
  left join public.items i on lower(btrim(i.name)) = lower(btrim(r.nm))
  where r.nm is not null and btrim(r.nm) <> ''
)
select json_build_object(
  '_k', 'rewards',
  'by_quest', (select coalesce(json_agg(x), '[]'::json) from (
      select quest, count(*) as rewards,
             count(*) filter (where cat = 'Relic') as relics,
             count(*) filter (where cat = 'Bottled Faerie') as faeries,
             count(*) filter (where cat in ('Snowball', 'Seasonal Snowball')) as snowballs,
             count(*) filter (where cat = 'Coupon') as coupons,
             count(*) filter (where cat = 'Codestones') as codestones,
             count(*) filter (where cat = 'Seasonal Pumpkin') as pumpkins,
             count(*) filter (where cat = 'Unlisted') as unlisted
      from j group by quest) x),
  'top', (select coalesce(json_agg(t), '[]'::json) from (
      select quest, nm, cat, rarity, img, n from (
        select quest, nm, cat, rarity, img, count(*) as n,
               row_number() over (partition by quest order by count(*) desc, nm) as rk
        from j
        where cat not in ('Bottled Faerie', 'Snowball', 'Seasonal Snowball', 'Coupon', 'Codestones', 'Seasonal Pumpkin')
        group by quest, nm, cat, rarity, img) s
      where rk <= 10 order by quest, n desc, nm) t),
  'groups', (select coalesce(json_agg(g), '[]'::json) from (
      select quest, cat, nm, img, count(*) as n from j
      where cat in ('Bottled Faerie', 'Snowball', 'Seasonal Snowball', 'Coupon', 'Seasonal Pumpkin')
      group by quest, cat, nm, img order by quest, n desc, nm) g),
  'unlisted_names', (select count(distinct lower(nm)) from j where cat = 'Unlisted')
) as d
$fn$;

revoke all on function public.dashboard_rewards() from public;
grant execute on function public.dashboard_rewards() to anon, authenticated, service_role;

create or replace function public.dashboard_requested()
returns json
language sql
stable
security definer
set search_path = public
as $fn$
with r as (
  select quest, unnest(array[req_item1, req_item2, req_item3, req_item4]) as nm from public.quest_rewards_ashadee
),
j as (
  select r.quest,
         coalesce(i.name, btrim(r.nm)) as nm,
         i.rarity,
         i.image_url as img,
         coalesce(i.category, 'Unlisted') as cat
  from r
  left join public.items i on lower(btrim(i.name)) = lower(btrim(r.nm))
  where r.nm is not null and btrim(r.nm) <> ''
)
select json_build_object(
  '_k', 'requested',
  'total', (select count(*) from j),
  'top_all', (select coalesce(json_agg(t), '[]'::json) from (
      select nm, rarity, cat, img, count(*) as n from j group by nm, rarity, cat, img order by n desc, nm limit 10) t),
  'by_quest', (select coalesce(json_agg(t), '[]'::json) from (
      select quest, nm, rarity, cat, img, n from (
        select quest, nm, rarity, cat, img, count(*) as n,
               row_number() over (partition by quest order by count(*) desc, nm) as rk
        from j group by quest, nm, rarity, cat, img) s
      where rk <= 10 order by quest, n desc, nm) t)
) as d
$fn$;

revoke all on function public.dashboard_requested() from public;
grant execute on function public.dashboard_requested() to anon, authenticated, service_role;
