-- DashCore baseline. Applied to znrxgcfdvsmqkvejyrbo with apply_migration.
-- Existing advisory scripts are historical patches, not a fresh install.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated, service_role;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,20}$'),
  full_name text check (length(full_name) <= 120),
  avatar_url text check (length(avatar_url) <= 2048),
  country_code text check (country_code ~ '^[A-Z]{2}$'),
  total_distance double precision not null default 0 check (total_distance between 0 and 10000000),
  max_speed double precision not null default 0 check (max_speed between 0 and 500),
  driver_level text not null default 'PRINCIPIANTE',
  updated_at timestamptz not null default now()
);
create index profiles_ranking_idx on public.profiles(total_distance desc, max_speed desc, id);

create table public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  settings_data jsonb not null default '{}' check (jsonb_typeof(settings_data) = 'object' and octet_length(settings_data::text) <= 131072),
  updated_at timestamptz not null default now()
);
create table public.user_styles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  style_id text not null check (length(style_id) between 1 and 64),
  source text not null default 'app',
  unlocked_at timestamptz not null default now(),
  unique(user_id, style_id)
);
create table public.vehicles (
  id text primary key check (id ~ '^[a-zA-Z0-9_-]{1,64}$'),
  name text not null,
  brand text not null,
  version text,
  engine text,
  model_url text,
  background_url text,
  model_bytes bigint check (model_bytes > 0),
  is_active boolean not null default false,
  updated_at timestamptz not null default now()
);
create table public.app_versions (
  id bigint generated always as identity primary key,
  version_name text not null,
  version_code bigint not null,
  min_version_code bigint not null default 1,
  title text not null,
  changelog text,
  download_url text not null,
  download_url_32 text,
  download_url_64 text,
  platform text not null default 'android',
  is_active boolean not null default false,
  is_mandatory boolean not null default false,
  published_at timestamptz not null default now(),
  unique(platform, version_code)
);
create table public.app_announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  message text not null,
  severity text not null default 'info',
  priority integer not null default 0 check (priority between 0 and 5),
  is_active boolean not null default false,
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.app_users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  country_code text,
  language_code text,
  timezone text,
  device_model text,
  manufacturer text,
  android_version text,
  dashcore_version text,
  dashcore_build integer,
  vehicle_selected_id text,
  location_approx jsonb,
  location_captured_at timestamptz,
  last_login_at timestamptz,
  updated_at timestamptz not null default now()
);
create table public.user_devices (
  user_id uuid primary key references auth.users(id) on delete cascade,
  device_model text,
  manufacturer text,
  android_version text,
  architecture text,
  app_version text,
  app_version_code integer,
  last_seen_at timestamptz not null default now(),
  metadata jsonb,
  updated_at timestamptz not null default now()
);
create table public.user_sessions (
  session_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  platform text,
  device_info jsonb
);
create index user_sessions_owner_idx on public.user_sessions(user_id, last_seen_at desc);
create table public.app_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  event_name text not null check (length(event_name) between 1 and 100),
  event_data jsonb check (octet_length(event_data::text) <= 16384),
  platform text,
  created_at timestamptz not null default now()
);
create index app_events_owner_time_idx on public.app_events(user_id, created_at desc);
create table public.consent_records (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  accepted boolean not null,
  version text not null,
  platform text,
  app_version text,
  timestamp timestamptz not null default now()
);
create index consent_records_owner_idx on public.consent_records(user_id, timestamp desc);
create table public.vehicle_telemetry_samples (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id text not null references public.vehicles(id),
  sampled_at timestamptz not null default now(),
  temperature_c double precision not null check (temperature_c between -30 and 250),
  voltage_v double precision not null check (voltage_v between 1 and 40),
  rpm integer not null check (rpm between 0 and 20000),
  speed_kmh integer not null check (speed_kmh between 0 and 500)
);
create index vehicle_samples_owner_idx on public.vehicle_telemetry_samples(user_id, sampled_at desc);
create index vehicle_samples_vehicle_idx on public.vehicle_telemetry_samples(vehicle_id, sampled_at desc);
create table public.technical_reports (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  reporter_name text,
  reporter_email text,
  subject text not null check (length(subject) between 1 and 200),
  message text not null check (length(message) between 1 and 10000),
  email_status text not null default 'pending',
  email_sent_at timestamptz,
  email_error text,
  email_message_id text,
  created_at timestamptz not null default now()
);
create index technical_reports_owner_idx on public.technical_reports(user_id, created_at desc);

-- Explicit grants; no anonymous access to user data, writes, or telemetry.
do $$
declare t text;
begin
  foreach t in array array['profiles','user_settings','user_styles','vehicles','app_versions','app_announcements','app_users','user_devices','user_sessions','app_events','consent_records','vehicle_telemetry_samples','technical_reports'] loop
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('alter table public.%I enable row level security', t);
  end loop;
  foreach t in array array['user_settings','user_styles','app_users','user_devices','user_sessions'] loop
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
    execute format('create policy owner_access on public.%I for all to authenticated using ((select auth.uid()) = %I) with check ((select auth.uid()) = %I)', t, case when t = 'app_users' then 'id' else 'user_id' end, case when t = 'app_users' then 'id' else 'user_id' end);
  end loop;
  foreach t in array array['vehicles','app_versions','app_announcements'] loop
    execute format('grant select on public.%I to anon, authenticated', t);
    execute format('create policy published_read on public.%I for select to anon, authenticated using (is_active)', t);
  end loop;
  foreach t in array array['app_events','consent_records','vehicle_telemetry_samples'] loop
    execute format('grant insert on public.%I to authenticated', t);
    execute format('create policy owner_insert on public.%I for insert to authenticated with check ((select auth.uid()) = user_id)', t);
  end loop;
end $$;
grant usage on sequence public.app_events_id_seq, public.consent_records_id_seq, public.vehicle_telemetry_samples_id_seq to authenticated;
grant select on public.profiles to authenticated;
grant update(username, full_name, avatar_url, country_code, updated_at) on public.profiles to authenticated;
create policy owner_read on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy owner_update on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare nickname text;
begin
  nickname := lower(new.raw_user_meta_data->>'username');
  if nickname is null or nickname !~ '^[a-z0-9_]{3,20}$' then
    nickname := 'driver_' || substr(replace(new.id::text, '-', ''), 1, 12);
  end if;
  if exists(select 1 from public.profiles where username = nickname) then
    nickname := 'driver_' || substr(replace(new.id::text, '-', ''), 1, 12);
  end if;
  insert into public.profiles(id, username, full_name, country_code)
  values(new.id, nickname, left(new.raw_user_meta_data->>'full_name', 120),
    case when new.raw_user_meta_data->>'country_code' ~ '^[A-Z]{2}$' then new.raw_user_meta_data->>'country_code' end);
  insert into public.user_settings(user_id) values(new.id);
  return new;
end $$;
revoke all on function private.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created after insert on auth.users for each row execute function private.handle_new_user();

create function private.username_available(candidate text) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and lower(trim(candidate)) ~ '^[a-z0-9_]{3,20}$'
    and not exists(select 1 from public.profiles where username = lower(trim(candidate)) and id <> auth.uid());
$$;
create function public.username_available(candidate text) returns boolean
language sql stable security invoker set search_path = '' as $$
  select private.username_available(candidate);
$$;
create function public.suggest_available_username(candidate text) returns text
language sql stable security invoker set search_path = '' as $$
  select case when public.username_available(candidate) then lower(trim(candidate)) else 'driver_' || substr(replace(auth.uid()::text, '-', ''), 1, 12) end;
$$;
create function public.update_my_profile(new_username text, new_full_name text default null, new_avatar_url text default null) returns void
language plpgsql security invoker set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  update public.profiles set username = lower(trim(new_username)),
    full_name = coalesce(new_full_name, full_name), avatar_url = coalesce(new_avatar_url, avatar_url), updated_at = now()
    where id = auth.uid();
end $$;
create function public.update_my_avatar(new_avatar_url text) returns void
language sql security invoker set search_path = '' as $$
  update public.profiles set avatar_url = new_avatar_url, updated_at = now() where id = auth.uid();
$$;
create function public.get_my_profile_completion() returns jsonb
language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object('complete', coalesce(length(trim(full_name)) >= 2 and length(username) >= 3, false))
  from public.profiles where id = auth.uid();
$$;
create function public.set_my_country(p_country_code text) returns void
language sql security invoker set search_path = '' as $$
  update public.profiles set country_code = upper(p_country_code), updated_at = now() where id = auth.uid();
  update public.app_users set country_code = upper(p_country_code), updated_at = now() where id = auth.uid();
$$;
create function private.sync_my_driving_stats(new_total_distance double precision, new_max_speed double precision) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if new_total_distance is null or new_max_speed is null or not(new_total_distance between 0 and 10000000) or not(new_max_speed between 0 and 500) then
    return jsonb_build_object('accepted', false, 'error_code', 'invalid_stats');
  end if;
  update public.profiles set total_distance = greatest(total_distance, new_total_distance), max_speed = greatest(max_speed, new_max_speed),
    driver_level = case when greatest(total_distance, new_total_distance) > 1000 then 'LEYENDA DEL ASFALTO'
      when greatest(total_distance, new_total_distance) > 500 then 'EXPERTO DASHCORE'
      when greatest(total_distance, new_total_distance) > 100 then 'CONDUCTOR AVANZADO'
      when greatest(total_distance, new_total_distance) > 20 then 'ENTUSIASTA' else 'PRINCIPIANTE' end,
    updated_at = now() where id = auth.uid()
    returning jsonb_build_object('accepted', true, 'total_distance', total_distance, 'max_speed', max_speed) into result;
  return result;
end $$;
create function public.sync_my_driving_stats(new_total_distance double precision, new_max_speed double precision) returns jsonb
language sql security invoker set search_path = '' as $$ select private.sync_my_driving_stats(new_total_distance, new_max_speed); $$;
create function private.dashleague_ranking() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(to_jsonb(r) order by r.position), '[]'::jsonb) from (
    select md5(id::text) as ranking_key, row_number() over(order by total_distance desc, max_speed desc, id) as position,
      username, full_name, country_code, avatar_url, total_distance, max_speed, id = auth.uid() as is_me
    from public.profiles where auth.uid() is not null
    order by total_distance desc, max_speed desc, id limit 50
  ) r;
$$;
create function public.get_dashleague_ranking_v3() returns jsonb
language sql stable security invoker set search_path = '' as $$ select private.dashleague_ranking(); $$;
create function public.get_active_remote_announcement() returns jsonb
language sql stable security invoker set search_path = '' as $$
  select to_jsonb(a) from public.app_announcements a
  where is_active and starts_at <= now() and (expires_at is null or expires_at > now())
  order by priority desc, created_at desc limit 1;
$$;

-- Only the Edge Functions (service_role) can consume shared rate limits.
create table private.request_limits (
  key text primary key,
  window_start timestamptz not null default now(),
  hits integer not null default 1
);
alter table private.request_limits enable row level security;
create function public.consume_request_limit(p_key text, p_limit integer, p_seconds integer) returns boolean
language plpgsql security invoker set search_path = '' as $$
declare n integer;
begin
  insert into private.request_limits as l(key) values(p_key)
  on conflict(key) do update set hits = case when l.window_start < now() - make_interval(secs => p_seconds) then 1 else l.hits + 1 end,
    window_start = case when l.window_start < now() - make_interval(secs => p_seconds) then now() else l.window_start end returning hits into n;
  return n <= p_limit;
end $$;
grant all on private.request_limits to service_role;

create view public.vehicle_telemetry_ranges with (security_invoker = true) as
select vehicle_id, count(*) as sample_count, avg(temperature_c) as avg_temperature_c,
  min(temperature_c) as min_temperature_c, max(temperature_c) as max_temperature_c,
  avg(voltage_v) as avg_voltage_v, avg(rpm) as avg_rpm, avg(speed_kmh) as avg_speed_kmh
from public.vehicle_telemetry_samples group by vehicle_id;
revoke all on public.vehicle_telemetry_ranges from anon, authenticated;

-- Limit permission changes to these newly created application functions.
do $$
declare f text;
begin
  foreach f in array array[
    'public.username_available(text)', 'private.username_available(text)',
    'public.suggest_available_username(text)', 'public.update_my_profile(text,text,text)',
    'public.update_my_avatar(text)', 'public.get_my_profile_completion()',
    'public.set_my_country(text)', 'public.sync_my_driving_stats(double precision,double precision)',
    'private.sync_my_driving_stats(double precision,double precision)',
    'public.get_dashleague_ranking_v3()', 'private.dashleague_ranking()',
    'public.get_active_remote_announcement()', 'public.consume_request_limit(text,integer,integer)'
  ] loop
    execute 'revoke execute on function ' || f || ' from public, anon, authenticated';
  end loop;
end $$;
grant execute on function public.username_available(text), public.suggest_available_username(text), public.update_my_profile(text,text,text),
  public.update_my_avatar(text), public.get_my_profile_completion(), public.set_my_country(text), public.sync_my_driving_stats(double precision,double precision),
  public.get_dashleague_ranking_v3() to authenticated;
grant execute on function private.username_available(text), private.sync_my_driving_stats(double precision,double precision), private.dashleague_ranking() to authenticated;
grant execute on function public.get_active_remote_announcement() to anon, authenticated;
grant execute on function public.consume_request_limit(text,integer,integer) to service_role;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types) values
  ('avatars','avatars',true,5242880,array['image/jpeg','image/png','image/webp']),
  ('style-previews','style-previews',true,4194304,array['image/jpeg','image/png','image/webp']),
  ('vehicles','vehicles',true,104857600,null);
create policy avatar_read on storage.objects for select to authenticated using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy avatar_insert on storage.objects for insert to authenticated with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy avatar_update on storage.objects for update to authenticated using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text) with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy avatar_delete on storage.objects for delete to authenticated using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
alter publication supabase_realtime add table public.app_announcements;
