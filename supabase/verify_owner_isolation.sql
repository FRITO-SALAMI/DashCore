-- Integration verification. All synthetic users and rows are rolled back.
begin;
select set_config('dashcore.test_owner', gen_random_uuid()::text, true),
       set_config('dashcore.test_other', gen_random_uuid()::text, true),
       set_config('dashcore.catalog_count', (select count(*)::text from public.vehicles), true);
insert into auth.users(id, email, aud, role, raw_user_meta_data, raw_app_meta_data)
select id::uuid, 'validation+' || id || '@example.invalid', 'authenticated', 'authenticated',
       jsonb_build_object('username', 'test_' || substr(replace(id, '-', ''), 1, 12)), '{}'::jsonb
from (values(current_setting('dashcore.test_owner')), (current_setting('dashcore.test_other'))) as u(id);
insert into public.user_vehicles(user_id,id,name,brand)
values (current_setting('dashcore.test_owner')::uuid,'custom_validation','Owner car','Test'),
       (current_setting('dashcore.test_other')::uuid,'custom_validation','Other car','Test');
set local role authenticated;
select set_config('request.jwt.claim.sub', current_setting('dashcore.test_owner'), true);
do $$
declare n integer; result jsonb;
begin
  if (select count(*) from public.profiles) <> 1 then raise exception 'Profile isolation failed'; end if;
  if (select count(*) from public.user_vehicles) <> 1 then raise exception 'Vehicle isolation failed'; end if;
  update public.user_vehicles set name='Not allowed' where user_id=current_setting('dashcore.test_other')::uuid;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'Cross-user update allowed'; end if;
  begin
    insert into public.user_vehicles(user_id,id,name,brand)
      values(current_setting('dashcore.test_other')::uuid,'custom_forged','Forged','Test');
    raise exception 'Cross-user insert allowed';
  exception when insufficient_privilege then null; end;
  begin
    update public.profiles set total_distance=999 where id=auth.uid();
    raise exception 'Direct stats update allowed';
  exception when insufficient_privilege then null; end;
  begin
    delete from public.vehicles;
    raise exception 'Shared catalog deletion allowed';
  exception when insufficient_privilege then null; end;
  result := public.sync_my_driving_stats(42,86);
  if result->>'accepted' <> 'true' or (result->>'total_distance')::numeric <> 42 then raise exception 'Stats RPC failed'; end if;
  result := public.sync_my_driving_stats(-1,86);
  if result->>'accepted' <> 'false' then raise exception 'Invalid stats accepted'; end if;
  perform public.sync_my_driving_stats(1,10);
  if (select total_distance from public.profiles where id=auth.uid()) <> 42 then raise exception 'Stats decreased'; end if;
end $$;
reset role;
-- This UUID was created above in this transaction. No existing account is targeted.
delete from auth.users where id=current_setting('dashcore.test_owner')::uuid;
do $$
begin
  if exists(select 1 from public.profiles where id=current_setting('dashcore.test_owner')::uuid)
    or exists(select 1 from public.user_settings where user_id=current_setting('dashcore.test_owner')::uuid)
    or exists(select 1 from public.user_vehicles where user_id=current_setting('dashcore.test_owner')::uuid)
    then raise exception 'Personal cascade incomplete'; end if;
  if not exists(select 1 from public.user_vehicles where user_id=current_setting('dashcore.test_other')::uuid and name='Other car')
    then raise exception 'Other user data changed'; end if;
  if (select count(*) from public.vehicles) <> current_setting('dashcore.catalog_count')::integer
    then raise exception 'Shared catalog changed'; end if;
end $$;
rollback;
select 'PASS: RLS isolation, forged writes, stats validation, owner cascade, shared catalog preserved; all test data rolled back' as verification;
