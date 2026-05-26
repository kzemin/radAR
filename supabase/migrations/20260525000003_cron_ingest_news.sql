-- Schedule ingest-news to run every 10 minutes.
--
-- The job calls the edge function over HTTP (pg_net) and authenticates with the
-- `x-cron-secret` header, paired with the function's CRON_SECRET env. The secret
-- itself lives in a database-level GUC (`app.cron_secret`) so this file stays
-- safe to check in. Set it once via the SQL editor:
--
--   alter database postgres set app.cron_secret to '<long-random-string>';
--
-- and add CRON_SECRET=<same-string> to the function's secrets in the dashboard.
-- The job picks it up via `current_setting('app.cron_secret', true)` at every run,
-- so rotating the secret only needs the two updates above — no migration rerun.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net  with schema extensions;

-- Drop the prior job if it exists so this migration is idempotent.
do $$
begin
    perform cron.unschedule('ingest-news-every-10-min');
exception when others then null;
end $$;

select cron.schedule(
    'ingest-news-every-10-min',
    '*/10 * * * *',
    $job$
    select net.http_post(
        url := 'https://oqgffwkehcmedwvgceku.supabase.co/functions/v1/ingest-news',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-cron-secret', coalesce(current_setting('app.cron_secret', true), '')
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 30000
    ) as request_id;
    $job$
);
