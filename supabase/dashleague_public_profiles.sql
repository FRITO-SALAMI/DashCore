-- Public, deliberately limited DashLeague profile returned to signed-in users.
-- Run once in Supabase SQL Editor before publishing the updated app.

create or replace function public.get_dashleague_ranking_v3()
returns table (
  ranking_key text,
  position bigint,
  username text,
  full_name text,
  country_code text,
  avatar_url text,
  total_distance double precision,
  max_speed double precision,
  is_me boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    md5(p.id::text) as ranking_key,
    row_number() over (
      order by coalesce(p.total_distance, 0) desc, coalesce(p.max_speed, 0) desc
    ) as position,
    coalesce(nullif(trim(p.username), ''), 'PILOTO') as username,
    coalesce(nullif(trim(p.full_name), ''), nullif(trim(p.username), ''), 'PILOTO') as full_name,
    upper(coalesce(nullif(trim(p.country_code), ''), '')) as country_code,
    p.avatar_url,
    coalesce(p.total_distance, 0)::double precision as total_distance,
    coalesce(p.max_speed, 0)::double precision as max_speed,
    p.id = auth.uid() as is_me
  from public.profiles p
  order by coalesce(p.total_distance, 0) desc, coalesce(p.max_speed, 0) desc
  limit 50;
$$;

revoke all on function public.get_dashleague_ranking_v3() from public;
grant execute on function public.get_dashleague_ranking_v3() to authenticated;
