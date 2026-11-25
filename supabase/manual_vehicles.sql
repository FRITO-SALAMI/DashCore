create table public.user_vehicles (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null check (id ~ '^custom_[a-zA-Z0-9_]{1,64}$'),
  name text not null check (length(name) between 1 and 100),
  brand text not null check (length(brand) between 1 and 80),
  version text check (length(version) <= 20),
  photo_path text,
  artwork_path text,
  updated_at timestamptz not null default now(),
  primary key(user_id, id),
  check (photo_path is null or photo_path = user_id::text || '/' || id || '/source.png'),
  check (artwork_path is null or artwork_path = user_id::text || '/' || id || '/artwork.png')
);
alter table public.user_vehicles enable row level security;
revoke all on public.user_vehicles from anon, authenticated;
grant select, insert, update, delete on public.user_vehicles to authenticated;
create policy owner_vehicles on public.user_vehicles for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('user-vehicles','user-vehicles',false,10485760,array['image/png']);
create policy owner_vehicle_images on storage.objects for all to authenticated
  using (bucket_id = 'user-vehicles' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'user-vehicles' and (storage.foldername(name))[1] = (select auth.uid())::text);
