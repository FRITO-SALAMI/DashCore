-- HISTÓRICO RETIRADO EN 2.0. NO EJECUTAR: ubicación/telemetría remota fueron eliminadas.
-- Ver supabase/README.md y privacy_local_only.sql.
-- Ejecutar una vez en Supabase > SQL Editor.
alter table public.profiles
  add column if not exists country_code text;
alter table public.app_users
  add column if not exists country_code text;

create or replace function public.set_my_country(p_country_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_country_code not in ('DO', 'US', 'MX', 'CO', 'ES', 'PR') then
    raise exception 'unsupported_country';
  end if;
  update public.profiles
    set country_code = p_country_code
    where id = auth.uid();
  update public.app_users
    set country_code = p_country_code, updated_at = now()
    where id = auth.uid();
end;
$$;
revoke all on function public.set_my_country(text) from public;
grant execute on function public.set_my_country(text) to authenticated;

create table if not exists public.vehicle_telemetry_samples (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id text not null,
  sampled_at timestamptz not null default now(),
  temperature_c double precision not null,
  voltage_v double precision not null,
  rpm integer not null,
  speed_kmh integer not null,
  constraint vehicle_telemetry_voltage_check check (voltage_v between 1 and 40),
  constraint vehicle_telemetry_temp_check check (temperature_c between -30 and 250)
);

alter table public.vehicle_telemetry_samples enable row level security;
drop policy if exists "users_insert_own_vehicle_samples"
  on public.vehicle_telemetry_samples;
create policy "users_insert_own_vehicle_samples"
on public.vehicle_telemetry_samples for insert to authenticated
with check (auth.uid() = user_id);

-- Los usuarios no pueden consultar ni modificar las muestras individuales.
revoke all on public.vehicle_telemetry_samples from anon, authenticated;
grant insert on public.vehicle_telemetry_samples to authenticated;
grant usage, select on sequence public.vehicle_telemetry_samples_id_seq
  to authenticated;

create index if not exists vehicle_telemetry_vehicle_time_idx
  on public.vehicle_telemetry_samples(vehicle_id, sampled_at desc);

create or replace view public.vehicle_telemetry_ranges as
select
  vehicle_id,
  count(*) as sample_count,
  round(avg(temperature_c)::numeric, 1) as avg_temperature_c,
  min(temperature_c) as min_temperature_c,
  max(temperature_c) as max_temperature_c,
  round(avg(voltage_v)::numeric, 2) as avg_voltage_v,
  min(voltage_v) as min_voltage_v,
  max(voltage_v) as max_voltage_v,
  round(avg(rpm)::numeric) as avg_rpm,
  round(avg(speed_kmh)::numeric, 1) as avg_speed_kmh,
  min(sampled_at) as first_sampled_at,
  max(sampled_at) as last_sampled_at
from public.vehicle_telemetry_samples
group by vehicle_id;

revoke all on public.vehicle_telemetry_ranges from anon, authenticated;
