# Networking & Data Roadmap

radAR currently runs on **100% local mock data** — no networking, no services, no
persistence. `AppContainer` is empty and `MapaStore` is seeded with
`MockNewsData.seed()` + `MockTickerData.items`. This document maps every piece of UI
that needs real data to a source, and lays out the pipeline and phased plan to feed it.

**Backend:** Supabase (Edge Functions + Postgres + cron).
**Guiding principle (from World Monitor):** the value isn't any single feed — it's the
**fan-in + dedup + cache** layer, done server-side. Clients hit one source of truth.

---

## 1. What needs real data

| # | Mock source | Shape | Consumed by | Real source |
|---|---|---|---|---|
| 1 | `MockNewsData.seed()` → `[NewsEvent]` | `headline, body, province(24), coordinate, timestamp, category(pol/eco/seg/soc/otro), severity(normal/breaking), sourceURL` | map pins, drawer list, callout, `activeProvinces` | **RSS + GDELT → dedup → LLM tag** |
| 2 | `MockTickerData` `.quote/.stat` | Dólar (oficial/blue/MEP/CCL), Merval, Riesgo país, Reservas BCRA, Soja, Petróleo | top ticker | **Financial APIs** (separate pipeline) |
| 3 | `MockTickerData` `.urgent(String)` | breaking one-liners | top ticker | **News pipeline** (severity=breaking) |
| 4 | `EventThumbnail` → `Image("congress")` | one hardcoded image for every card | card/callout thumbnail | **per-event image** (RSS `<enclosure>` / og:image) |

**Stays local (not fed):** province/extras/world GeoJSON and province centroids — static
reference geometry.

There are really **two independent pipelines**: a large **news** one (#1, #3, #4) and a
small **market-ticker** one (#2).

---

## 2. Architecture

```
~15 AR RSS feeds  +  GDELT (Argentina, geocoded)  [+ ACLED later]
        ↓  (Supabase Edge Function, cron ~10 min)
   fetch in parallel → dedup (headline-sim + 24h window)
        ↓
   Claude Haiku per new item → {province, category, severity, coordinate?}
        ↓
   news_events table  (+ source tier, image_url, also_covered_by)
        ↓
   iOS reads one endpoint → existing map / drawer / callout UI
```

Market data runs a parallel, simpler function into a `market_quotes` table.

---

## 3. Pipeline A — News

**Sources**
- **RSS** (direct, no API): Clarín, La Nación, Infobae, TN, Página/12, Perfil, Ámbito +
  regional (La Voz de Córdoba, Los Andes Mendoza, La Capital Rosario, El Tribuno Salta,
  Río Negro). Gives headline / body / image / sourceURL.
- **GDELT** filtered to Argentina — the only free source that returns **lat/lon already
  attached**. RSS items without coordinates fall back to `province.centroid` (the
  `NewsEvent` model already does this).
- **ACLED** (later) — clean Argentina security/protest events with coordinates; free with
  registration. Powers a future security layer.

**Flow:** fetch in parallel → dedup by headline similarity within a 24h window → tag new
items → upsert.

**Tagging (LLM):** Claude **Haiku** per item → `{province (1 of 24), category (1 of 5),
severity, coordinate?}`. It's a small extraction/classification task, so the smallest model
is the right tool; bigger models add cost with no accuracy gain.
- *Cost lever:* province is largely a lookup (city→province gazetteer + name matching).
  Start Haiku-on-everything to ship, then move to **rules-first, Haiku-only-on-ambiguous**
  to cut cost. Rules-only is the free fallback.
- *Cost lever:* prompt-cache the static instructions + province list; only tag **new**
  (post-dedup) items.

**Source tiering:** T1 wire → T4 aggregator. Dedup keeps the highest-tier source and links
the rest as `also_covered_by`. Tier can render on cards (fits the analytical aesthetic).
Model additions needed: `source`, `tier`, `image_url`, `also_covered_by`.

**Skip for v1:** Telegram/OSINT scraping, cyber/flights/ships — irrelevant at province
granularity.

---

## 4. Pipeline B — Market ticker

- **Dólar** (oficial/blue/MEP/CCL): clean free APIs (dolarapi / Bluelytics).
- **Reservas BCRA:** BCRA estadísticas API (free).
- **Riesgo país / Merval / Soja / Petróleo:** ⚠️ no clean free API — needs scraping
  (free, fragile) or a paid provider. **Main sourcing risk.** Options: scrape, drop these
  tiles for v1, or pay. These are cosmetic vs the map, so deferrable.
- Cadence 5–15 min; cache server-side; serve as one `market_quotes` payload.

---

## 5. Backend (Supabase)

**Schema (sketch)**

```sql
-- news
create table news_events (
  id            uuid primary key default gen_random_uuid(),
  headline      text not null,
  body          text not null,
  province      text not null,          -- AR-* code (ArgentineProvince.rawValue)
  lat           double precision,       -- null → app uses province centroid
  lon           double precision,
  timestamp     timestamptz not null,
  category      text not null,          -- politica|economia|seguridad|social|otro
  severity      text not null default 'normal',  -- normal|breaking
  source        text,
  tier          int,                    -- 1..4
  source_url    text,
  image_url     text,
  dedup_key     text unique,            -- headline-hash + day
  created_at    timestamptz default now()
);
create index on news_events (timestamp desc);

-- market ticker
create table market_quotes (
  key        text primary key,          -- dolar_oficial, merval, riesgo_pais, ...
  label      text not null,
  value      text not null,
  change     text,
  kind       text not null,             -- quote|stat
  updated_at timestamptz default now()
);

-- feed registry / tiering
create table sources (
  id    text primary key,
  name  text not null,
  url   text not null,
  tier  int not null,
  kind  text not null                   -- rss|gdelt|acled
);
```

- **Edge Functions:** `ingest-news` (cron ~10 min), `ingest-market` (cron ~5–15 min).
- **RLS:** anon read-only on `news_events` / `market_quotes`; writes only from the
  functions (service role).
- **Cache:** functions write the deduped result; the app reads the table (single source of
  truth). The 10-min cron also keeps the free-tier project from idling.

---

## 6. iOS changes

- **`NewsService` / `MarketService` protocols** with live (Supabase) and mock impls; wire
  via `AppContainer` (today it's empty). Keep `MockNewsService` so the app builds while the
  backend comes up.
- **`MapaStore`:** load async instead of `MockNewsData.seed()`; add
  `loading / loaded / empty / error` state (today `events` is set once in `init`).
  Pull-to-refresh + refresh on foreground.
- **Models:** `Decodable` DTOs mapping to `NewsEvent`; add `source`, `tier`, `imageURL`.
- **`EventThumbnail`:** load remote `imageURL` (AsyncImage + cache); keep the category
  `symbolName` as the fallback.
- **Offline:** cache the last payload locally so the map isn't empty on launch; Spanish
  error snackbar on failure.

---

## 7. Cost (mostly free)

| Piece | Cost |
|---|---|
| Supabase (Postgres + Edge Functions + cron) | **Free tier** — far above this volume |
| RSS feeds | Free |
| GDELT (geocoded) | Free |
| ACLED (later) | Free (registration) |
| Dólar APIs + BCRA reservas | Free |
| Per-event images | Free (link publishers' URLs, not hosted) |
| **LLM tagging (Haiku)** | ~$1–10/mo at a few hundred new articles/day; prompt caching + dedup cut it sharply; **$0 rules-only** |
| Riesgo país / Merval / commodities | ⚠️ scrape (free, fragile) or paid provider |

**Net:** core map runs free or a couple dollars/month. The only thing that could force a
spend is the financial ticker tiles — cosmetic vs the map.
*Check current Haiku pricing (varies by version); Supabase free-tier limits (500 MB DB,
function invocations) are well above this app's needs.*

---

## 8. Phases

1. **Supabase schema** + RLS (read-only).
2. **`ingest-news` Edge Function v1:** RSS + GDELT → dedup → Haiku → upsert (cron).
3. **iOS read path:** `NewsService` + `MapaStore` async + states + offline cache.
   *(App now runs on real news.)*
4. **Images** (per-event) + **source tiering** on cards.
5. **Market ticker** pipeline (after the riesgo-país / Merval sourcing decision).
6. *(Later)* ACLED security layer; `also_covered_by` linking.

---

## 9. Decisions

- ✅ **Backend:** Supabase.
- **LLM:** ship Haiku-on-everything, add rules to cut cost once we see real data.
- ⏳ **Market data** (riesgo país / Merval): scrape vs paid vs drop for v1 — TBD.
- **Refresh:** cron-push to Supabase + app polls on foreground.
