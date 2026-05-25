// ingest-news — Supabase Edge Function (Deno)
//
// Reads RSS feeds from `sources`, dedups by article link, tags each new item with
// gpt-4o-mini (scope / province / category / severity), and upserts into
// `news_events`. Meant to run on a cron (~10 min).
//
// v1 scope: RSS only; flat 24h expires_at. Follow-ons (NETWORKING_ROADMAP.md):
// GDELT source, the day-aware expires_at window via `holidays`, story threading,
// and a rules-first tagger to cut LLM cost.
//
// NOTE: not yet deploy-tested — expect to iterate on real feed/LLM output.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { XMLParser } from "https://esm.sh/fast-xml-parser@4.4.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
// Prefer an explicit secret — the auto-injected legacy SUPABASE_SERVICE_ROLE_KEY
// isn't reliable under the new (publishable/secret) key model.
const SERVICE_KEY = (Deno.env.get("RADAR_SERVICE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
const OPENAI_API_KEY = (Deno.env.get("OPENAI_API_KEY") ?? "").trim();

const PROVINCE_CODES = [
  "AR-A", "AR-B", "AR-C", "AR-D", "AR-E", "AR-F", "AR-G", "AR-H", "AR-J", "AR-K",
  "AR-L", "AR-M", "AR-N", "AR-P", "AR-Q", "AR-R", "AR-S", "AR-T", "AR-U", "AR-V",
  "AR-W", "AR-X", "AR-Y", "AR-Z",
];
const CATEGORIES = ["politica", "economia", "seguridad", "social", "otro"];
const LIVE_WINDOW_HOURS = 24; // flat for v1; day-aware window is a follow-on
const MAX_PER_RUN = 30; // cap OpenAI calls per invocation; backlog drains over runs

const xml = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: "@_" });

interface FeedItem {
  title: string;
  body: string;
  link: string;
  occurredAt: string;
  imageUrl: string | null;
  sourceId: string;
  tier: number;
}
interface Tag {
  scope: "provincial" | "national";
  province: string; // AR-* code or "none"
  category: string;
  severity: "normal" | "breaking";
}

Deno.serve(async () => {
  if (!OPENAI_API_KEY) return json({ error: "OPENAI_API_KEY not set" }, 500);
  if (!SERVICE_KEY) return json({ error: "service key not set — add the RADAR_SERVICE_KEY secret" }, 500);
  const db = createClient(SUPABASE_URL, SERVICE_KEY);

  const { data: sources, error: srcErr } = await db
    .from("sources").select("id, url, tier").eq("kind", "rss");
  if (srcErr) return json({ error: srcErr.message, serviceKeyLen: SERVICE_KEY.length }, 500);
  if (!sources?.length) return json({ message: "no rss sources configured" }, 200);

  // Fetch + parse every feed; a bad feed is skipped, not fatal.
  const items: FeedItem[] = [];
  await Promise.all(sources.map(async (s) => {
    try {
      const res = await fetchWithTimeout(s.url, 8000);
      if (!res.ok) return;
      for (const it of rssItems(xml.parse(await res.text()))) {
        const link = str(it.link);
        const title = clean(str(it.title));
        if (!link || !title) continue;
        items.push({
          title,
          body: clean(str(it.description ?? it["content:encoded"] ?? "")),
          link,
          occurredAt: toISO(str(it.pubDate ?? it.published ?? it.updated)) ?? new Date().toISOString(),
          imageUrl: imageFrom(it),
          sourceId: s.id,
          tier: s.tier,
        });
      }
    } catch (_) { /* skip bad feed */ }
  }));

  // Drop anything we already stored (dedup_key = link).
  const links = [...new Set(items.map((i) => i.link))];
  const known = new Set<string>();
  for (const batch of chunk(links, 200)) {
    const { data } = await db.from("news_events").select("dedup_key").in("dedup_key", batch);
    for (const r of data ?? []) known.add(r.dedup_key);
  }
  // Cap OpenAI calls per run so the first (all-fresh) invocation completes and
  // upserts instead of timing out; the backlog drains over later runs / cron ticks.
  const allFresh = dedupeByLink(items).filter((i) => !known.has(i.link));
  const fresh = allFresh.slice(0, MAX_PER_RUN);

  // Tag + build rows.
  const rows = [];
  let tagFailures = 0;
  let firstTagError: string | null = null;
  for (const item of fresh) {
    const result = await tagItem(item);
    if ("error" in result) {
      tagFailures++;
      if (!firstTagError) firstTagError = result.error;
      continue;
    }
    const tag = result.tag;
    const province = tag.scope === "provincial"
      ? (tag.province !== "none" ? tag.province : null)
      : null;
    if (tag.scope === "provincial" && !province) continue;
    rows.push({
      headline: item.title,
      body: item.body || item.title,
      scope: tag.scope,
      province,
      occurred_at: item.occurredAt,
      expires_at: new Date(Date.parse(item.occurredAt) + LIVE_WINDOW_HOURS * 3_600_000).toISOString(),
      category: CATEGORIES.includes(tag.category) ? tag.category : "otro",
      severity: tag.severity === "breaking" ? "breaking" : "normal",
      source: item.sourceId,
      tier: item.tier,
      source_url: item.link,
      image_url: item.imageUrl,
      dedup_key: item.link,
    });
  }

  let inserted = 0;
  if (rows.length) {
    const { error, count } = await db
      .from("news_events")
      .upsert(rows, { onConflict: "dedup_key", ignoreDuplicates: true, count: "exact" });
    if (error) return json({ error: error.message }, 500);
    inserted = count ?? rows.length;
  }
  return json({ feeds: sources.length, candidates: items.length, backlog: allFresh.length, processed: fresh.length, inserted, tagFailures, firstTagError }, 200);
});

// ── helpers ──────────────────────────────────────────────────────────────────
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}
async function fetchWithTimeout(url: string, ms: number): Promise<Response> {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), ms);
  try { return await fetch(url, { signal: ctrl.signal }); } finally { clearTimeout(t); }
}
// deno-lint-ignore no-explicit-any
function rssItems(parsed: any): any[] {
  const ch = parsed?.rss?.channel;
  if (ch?.item) return Array.isArray(ch.item) ? ch.item : [ch.item];
  const feed = parsed?.feed; // Atom
  if (feed?.entry) return Array.isArray(feed.entry) ? feed.entry : [feed.entry];
  return [];
}
// deno-lint-ignore no-explicit-any
function str(v: any): string {
  if (v == null) return "";
  if (typeof v === "string") return v;
  if (typeof v === "object") return str(v["#text"] ?? v["@_href"] ?? "");
  return String(v);
}
function clean(s: string): string {
  return s.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}
function toISO(s: string): string | null {
  const t = Date.parse(s);
  return Number.isNaN(t) ? null : new Date(t).toISOString();
}
// deno-lint-ignore no-explicit-any
function imageFrom(it: any): string | null {
  return str(it.enclosure?.["@_url"]) ||
    str(it["media:content"]?.["@_url"] ?? it["media:thumbnail"]?.["@_url"]) || null;
}
function dedupeByLink(items: FeedItem[]): FeedItem[] {
  const seen = new Set<string>();
  return items.filter((i) => (seen.has(i.link) ? false : (seen.add(i.link), true)));
}
function chunk<T>(arr: T[], n: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += n) out.push(arr.slice(i, i + n));
  return out;
}
async function tagItem(item: FeedItem): Promise<{ tag: Tag } | { error: string }> {
  const system = `Sos un clasificador de noticias argentinas. Devolvé SOLO el JSON pedido.
- scope: "national" si la noticia no es de una provincia puntual (p. ej. Congreso sin lugar, dólar, medidas nacionales); si tiene lugar claro, "provincial".
- province: código ISO AR-* de la provincia, o "none" si scope es national. Noticias de Malvinas → "AR-V".
- category: una de ${CATEGORIES.join(", ")}.
- severity: "breaking" sólo si es urgente/de último momento; si no, "normal".`;
  const user = `Título: ${item.title}\nResumen: ${item.body}`.slice(0, 1500);
  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "content-type": "application/json", authorization: `Bearer ${OPENAI_API_KEY}` },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        temperature: 0,
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "news_tag",
            strict: true,
            schema: {
              type: "object",
              additionalProperties: false,
              required: ["scope", "province", "category", "severity"],
              properties: {
                scope: { type: "string", enum: ["provincial", "national"] },
                province: { type: "string", enum: [...PROVINCE_CODES, "none"] },
                category: { type: "string", enum: CATEGORIES },
                severity: { type: "string", enum: ["normal", "breaking"] },
              },
            },
          },
        },
        messages: [{ role: "system", content: system }, { role: "user", content: user }],
      }),
    });
    if (!res.ok) return { error: `openai ${res.status}: ${(await res.text()).slice(0, 300)}` };
    const data = await res.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) return { error: `no content: ${JSON.stringify(data).slice(0, 300)}` };
    return { tag: JSON.parse(content) as Tag };
  } catch (e) {
    return { error: String(e).slice(0, 300) };
  }
}
