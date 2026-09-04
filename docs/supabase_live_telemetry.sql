-- Run in the Supabase SQL editor after reviewing retention and admin roles.
create table if not exists public.live_vehicle_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  captured_at timestamptz not null default now(),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy_m real,
  heading_deg real,
  gps_speed_kmh real,
  obd_connected boolean not null default false,
  speed_kmh real,
  rpm integer,
  engine_temp_c real,
  voltage_v real,
  fuel_percent real,
  odometer real
);

alter table public.live_vehicle_state enable row level security;

create policy "users read own live vehicle state"
on public.live_vehicle_state for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "users insert own live vehicle state"
on public.live_vehicle_state for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "users update own live vehicle state"
on public.live_vehicle_state for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "users delete own live vehicle state"
on public.live_vehicle_state for delete
to authenticated
using ((select auth.uid()) = user_id);

-- Enable only this table in Supabase Realtime after the consent flow is live:
-- alter publication supabase_realtime add table public.live_vehicle_state;

-- The separate monitoring application should never contain the service-role
-- key. Give an operator account a server-side role and expose only the rows it
-- is allowed to see through a secured backend/API.
