-- APNs device tokens for breaking-news push. The app upserts its token here on
-- launch; the ingest function reads them (via the service role) to fan out a push
-- whenever a `breaking` event is freshly inserted.
--
-- Tokens are opaque and low-value, so anon insert/update is allowed (the app
-- ships only the publishable key). The service role reads them server-side.

create table if not exists device_tokens (
    token       text primary key,
    platform    text not null default 'ios',
    updated_at  timestamptz not null default now()
);

alter table device_tokens enable row level security;

-- App registers/refreshes its own token (upsert = insert + update on conflict).
create policy "device_tokens insert" on device_tokens
    for insert to anon, authenticated with check (true);
create policy "device_tokens update" on device_tokens
    for update to anon, authenticated using (true) with check (true);

grant insert, update on device_tokens to anon, authenticated;
grant all on device_tokens to service_role;
