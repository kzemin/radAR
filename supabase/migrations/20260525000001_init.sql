-- radAR — news + market schema (v1)
--
-- Applied to a fresh Supabase project. The iOS app reads `news_events` and
-- `market_quotes` anonymously (read-only); everything is written by the ingestion
-- Edge Functions using the service role (which bypasses RLS). `sources` and
-- `holidays` are server-only.
--
-- Design decisions captured here (see NETWORKING_ROADMAP.md):
--   • scope         — provincial vs national (national highlights the whole country)
--   • dedup_key     — upsert key, drops repeats of the same item
--   • story_key     — groups continuations of one story (threading, used later)
--   • expires_at    — server-computed drop time using the day-aware "last workable
--                     day" window + the feriados calendar; the app just hides events
--                     where now >= expires_at (keeps pins/provinces/drawer in sync)
--   • holidays      — feeds the window (Friday-holiday → anchor Thursday, etc.)

-- ── Source feeds + tiering ─────────────────────────────────────────────────────
create table if not exists sources (
    id    text primary key,          -- stable slug, e.g. 'clarin', 'gdelt'
    name  text not null,
    url   text,                      -- feed URL (null for API sources like GDELT)
    tier  int  not null default 4,   -- 1 wire … 4 aggregator
    kind  text not null check (kind in ('rss', 'gdelt', 'acled'))
);

-- ── Argentine holidays (feriados) ──────────────────────────────────────────────
-- Not computable (trasladables + decreed puentes), so seed per year from a feriados
-- source. Server-only — the app never reads this; it relies on expires_at.
create table if not exists holidays (
    day   date primary key,          -- feriado date in ART
    name  text not null
);

-- ── News events ────────────────────────────────────────────────────────────────
create table if not exists news_events (
    id          uuid primary key default gen_random_uuid(),
    headline    text not null,
    body        text not null,
    scope       text not null default 'provincial'
                    check (scope in ('provincial', 'national')),
    province    text,                -- AR-* code; null when scope = 'national'
    lat         double precision,    -- null → app falls back to province centroid
    lon         double precision,
    occurred_at timestamptz not null,
    expires_at  timestamptz not null,
    category    text not null
                    check (category in ('politica', 'economia', 'seguridad', 'social', 'otro')),
    severity    text not null default 'normal'
                    check (severity in ('normal', 'breaking')),
    source      text references sources (id),
    tier        int,                 -- denormalized source tier for quick reads
    source_url  text,
    image_url   text,
    dedup_key   text not null unique,
    story_key   text,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    -- a provincial event must name a province; a national one must not need to
    check (scope = 'national' or province is not null)
);

create index if not exists news_events_occurred_idx on news_events (occurred_at desc);
create index if not exists news_events_expires_idx  on news_events (expires_at);
create index if not exists news_events_story_idx    on news_events (story_key);

-- ── Market ticker ──────────────────────────────────────────────────────────────
create table if not exists market_quotes (
    key        text primary key,     -- 'dolar_oficial', 'merval', 'riesgo_pais', …
    label      text not null,
    value      text not null,
    change     text,                 -- e.g. '+0,8%' (null for stats)
    kind       text not null check (kind in ('quote', 'stat')),
    updated_at timestamptz not null default now()
);

-- ── RLS ────────────────────────────────────────────────────────────────────────
alter table news_events   enable row level security;
alter table market_quotes enable row level security;
alter table sources       enable row level security;
alter table holidays      enable row level security;

-- app reads live news + market anonymously; writes go through the service role
create policy "news_events read" on news_events
    for select using (true);
create policy "market_quotes read" on market_quotes
    for select using (true);
-- no anon policies on sources / holidays → server-only

-- Explicit read grants so the app works regardless of the project's
-- "Automatically expose new tables" setting. `sources` / `holidays` are omitted on
-- purpose — they stay server-only (and RLS-denied even if exposed).
grant usage on schema public to anon, authenticated;
grant select on news_events, market_quotes to anon, authenticated;
