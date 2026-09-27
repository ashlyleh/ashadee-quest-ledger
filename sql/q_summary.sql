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
