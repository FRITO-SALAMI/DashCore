-- Catálogo remoto de vehículos para DashCore.
create table if not exists public.vehicles (
  id text primary key,
  name text not null,
  brand text not null,
  year text,
  engine text,
  model_url text not null,
  background_url text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  updated_at timestamptz not null default now()
);

-- Compatible con una tabla vehicles creada anteriormente.
alter table public.vehicles add column if not exists year text;
alter table public.vehicles add column if not exists engine text;
alter table public.vehicles add column if not exists model_url text;
alter table public.vehicles add column if not exists background_url text;
alter table public.vehicles add column if not exists is_active boolean not null default true;
alter table public.vehicles add column if not exists sort_order integer not null default 0;
alter table public.vehicles add column if not exists updated_at timestamptz not null default now();

alter table public.vehicles enable row level security;

create policy "public reads active vehicle catalog"
on public.vehicles for select
to anon, authenticated
using (is_active = true);

-- En Supabase Storage crea un bucket público llamado vehicle-resources.
-- Sube allí cada .glb y fondo, y guarda sus URL públicas en model_url y
-- background_url. No uses service_role en la aplicación.

-- Ejemplo:
-- insert into public.vehicles
--   (id, name, brand, year, model_url, background_url, sort_order)
-- values
--   ('optima_2012', 'KIA OPTIMA 2012', 'KIA', '2012',
--    'https://TU_PROYECTO.supabase.co/storage/v1/object/public/vehicle-resources/kiaOptima2012.glb',
--    'https://TU_PROYECTO.supabase.co/storage/v1/object/public/vehicle-resources/Kiaoptima12_bg.png', 10);

create index if not exists vehicles_active_sort_idx
on public.vehicles (is_active, sort_order, name);
