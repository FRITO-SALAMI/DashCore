-- Ejecutar una vez en Supabase > SQL Editor.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars', 'avatars', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "users_upload_own_avatar" on storage.objects;
create policy "users_upload_own_avatar" on storage.objects
for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "users_update_own_avatar" on storage.objects;
create policy "users_update_own_avatar" on storage.objects
for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "users_read_own_avatar_object" on storage.objects;
create policy "users_read_own_avatar_object" on storage.objects
for select to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create or replace function public.update_my_avatar(new_avatar_url text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  if new_avatar_url is null or length(new_avatar_url) > 2048 then
    raise exception 'invalid_avatar_url';
  end if;
  update public.profiles
  set avatar_url = new_avatar_url
  where id = auth.uid();
end;
$$;
revoke all on function public.update_my_avatar(text) from public, anon;
grant execute on function public.update_my_avatar(text) to authenticated;

create or replace function public.registration_email_in_use(candidate_email text)
returns boolean
language sql
security definer
stable
set search_path = public, auth
as $$
  select exists (
    select 1 from auth.users
    where lower(email) = lower(trim(candidate_email))
  );
$$;
revoke all on function public.registration_email_in_use(text) from public;
grant execute on function public.registration_email_in_use(text) to anon, authenticated;
