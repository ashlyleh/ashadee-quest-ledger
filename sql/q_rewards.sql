with r as (
  select quest, unnest(array[item1, item2, item3]) as nm from public.quest_rewards_ashadee
),
j as (
  select r.quest,
         coalesce(i.name, btrim(r.nm)) as nm,
         coalesce(i.category, case when lower(btrim(r.nm)) = 'codestones' then 'Codestones' else 'Unlisted' end) as cat,
         i.rarity
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
      select quest, nm, cat, rarity, n from (
        select quest, nm, cat, rarity, count(*) as n,
               row_number() over (partition by quest order by count(*) desc, nm) as rk
        from j
        where cat not in ('Bottled Faerie', 'Snowball', 'Seasonal Snowball', 'Coupon', 'Codestones', 'Seasonal Pumpkin')
        group by quest, nm, cat, rarity) s
      where rk <= 10 order by quest, n desc, nm) t),
  'groups', (select coalesce(json_agg(g), '[]'::json) from (
      select quest, cat, nm, count(*) as n from j
      where cat in ('Bottled Faerie', 'Snowball', 'Seasonal Snowball', 'Coupon', 'Seasonal Pumpkin')
      group by quest, cat, nm order by quest, n desc, nm) g),
  'unlisted_names', (select count(distinct lower(nm)) from j where cat = 'Unlisted')
) as d
