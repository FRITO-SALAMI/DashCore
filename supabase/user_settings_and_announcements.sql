-- Ejecutar una vez en Supabase > SQL Editor.
alter table public.user_settings
  add column if not exists settings_data jsonb not null default '{}'::jsonb;

alter table public.user_settings enable row level security;

drop policy if exists "users_read_own_settings" on public.user_settings;
create policy "users_read_own_settings" on public.user_settings
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "users_write_own_settings" on public.user_settings;
create policy "users_write_own_settings" on public.user_settings
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "users_update_own_settings" on public.user_settings;
create policy "users_update_own_settings" on public.user_settings
for update to authenticated using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- El sondeo de la app funciona aunque Realtime no esté habilitado. Esta línea
-- activa además la entrega instantánea por WebSocket; ignora duplicate_object.
do $$ begin
  alter publication supabase_realtime add table public.app_announcements;
exception when duplicate_object then null;
end $$;
