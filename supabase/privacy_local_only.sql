-- Applied after dashcore_baseline. The removed tables were verified empty.
-- GPS, routes and automatic performance samples stay on the device in v2.
drop view public.vehicle_telemetry_ranges;
drop table public.vehicle_telemetry_samples;
drop table public.app_events;
alter table public.app_users drop column location_approx, drop column location_captured_at;
-- These are intentionally backend-only tables, including in the advisors.
create policy service_reports on public.technical_reports for all to service_role using (true) with check (true);
create policy service_limits on private.request_limits for all to service_role using (true) with check (true);
