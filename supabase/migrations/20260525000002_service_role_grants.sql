-- The project has "Automatically expose new tables" off, so the `service_role`
-- role didn't receive privileges on the v1 tables. The ingestion Edge Function
-- runs as service_role and needs full access — it bypasses RLS but still requires
-- table grants. (The initial migration granted only anon/authenticated.)
grant usage on schema public to service_role;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
