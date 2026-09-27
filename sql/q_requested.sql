with r as (
  select quest, unnest(array[req_item1, req_item2, req_item3, req_item4]) as nm from public.quest_rewards_ashadee
),
j as (
  select r.quest,
         coalesce(i.name, btrim(r.nm)) as nm,
         i.rarity,
         coalesce(i.category, 'Unlisted') as cat
  from r
  left join public.items i on lower(btrim(i.name)) = lower(btrim(r.nm))
  where r.nm is not null and btrim(r.nm) <> ''
)
select json_build_object(
  '_k', 'requested',
  'total', (select count(*) from j),
  'top_all', (select coalesce(json_agg(t), '[]'::json) from (
      select nm, rarity, cat, count(*) as n from j group by nm, rarity, cat order by n desc, nm limit 10) t),
  'by_quest', (select coalesce(json_agg(t), '[]'::json) from (
      select quest, nm, rarity, cat, n from (
        select quest, nm, rarity, cat, count(*) as n,
               row_number() over (partition by quest order by count(*) desc, nm) as rk
        from j group by quest, nm, rarity, cat) s
      where rk <= 10 order by quest, n desc, nm) t)
) as d
