// ingest-news — Supabase Edge Function (Deno)
//
// Reads RSS feeds from `sources`, dedups by article link, tags each new item with
// gpt-4o-mini (scope / province / category / severity), and upserts into
// `news_events`. Meant to run on a cron (~10 min).
//
// Day-aware expires_at: a story stays live until the end of the next business
// day in ART (skipping weekends + the seeded `holidays` table), so Friday and
// pre-holiday news survive the gap instead of dropping off into an empty map.
// Follow-ons (NETWORKING_ROADMAP.md): GDELT, story threading, rules-first tagger.
//
// NOTE: not yet deploy-tested — expect to iterate on real feed/LLM output.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { XMLParser } from "https://esm.sh/fast-xml-parser@4.4.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
// Prefer an explicit secret — the auto-injected legacy SUPABASE_SERVICE_ROLE_KEY
// isn't reliable under the new (publishable/secret) key model.
const SERVICE_KEY = (Deno.env.get("RADAR_SERVICE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
const OPENAI_API_KEY = (Deno.env.get("OPENAI_API_KEY") ?? "").trim();
// Optional shared secret — when set, callers (the cron) must send it via the
// x-cron-secret header. Inert until you set the CRON_SECRET env var.
const CRON_SECRET = (Deno.env.get("CRON_SECRET") ?? "").trim();

// APNs (breaking-news push). All optional — if any is unset, pushes are skipped
// silently and the rest of ingestion is unaffected.
const APNS_KEY = (Deno.env.get("APNS_KEY") ?? "").trim();          // .p8 PEM contents
const APNS_KEY_ID = (Deno.env.get("APNS_KEY_ID") ?? "").trim();    // 10-char key id
const APNS_TEAM_ID = (Deno.env.get("APNS_TEAM_ID") ?? "").trim();  // 10-char team id
const APNS_TOPIC = (Deno.env.get("APNS_TOPIC") ?? "").trim();      // bundle id, e.g. kzemin.radAR
// Production by default; set to api.sandbox.push.apple.com for Xcode dev builds.
const APNS_HOST = (Deno.env.get("APNS_HOST") ?? "api.push.apple.com").trim();

const PROVINCE_CODES = [
  "AR-A", "AR-B", "AR-C", "AR-D", "AR-E", "AR-F", "AR-G", "AR-H", "AR-J", "AR-K",
  "AR-L", "AR-M", "AR-N", "AR-P", "AR-Q", "AR-R", "AR-S", "AR-T", "AR-U", "AR-V",
  "AR-W", "AR-X", "AR-Y", "AR-Z",
];
const CATEGORIES = ["politica", "economia", "seguridad", "social", "deportes", "otro"];
const MAX_PER_RUN = 30; // cap OpenAI calls per invocation; backlog drains over runs
const AR_OFFSET_HOURS = -3; // Argentina is UTC-3, no DST since 2009

const xml = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: "@_" });

interface FeedItem {
  title: string;
  body: string;
  link: string;
  occurredAt: string;
  expiresAt: string;
  imageUrl: string | null;
  sourceId: string;
  tier: number;
}
interface Tag {
  relevant: boolean;
  scope: "provincial" | "national";
  province: string; // AR-* code or "none"
  category: string;
  severity: "normal" | "breaking";
}

Deno.serve(async (req) => {
  // Accept either an explicit `x-cron-secret` header (manual curl) or the secret
  // sent as `Authorization: Bearer <secret>` (pg_cron + pg_net path, since pg_net
  // is unreliable about forwarding custom headers but always preserves Authorization).
  if (CRON_SECRET) {
    const fromCustom = req.headers.get("x-cron-secret");
    const bearer = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
    if (fromCustom !== CRON_SECRET && bearer !== CRON_SECRET) {
      return json({ error: "unauthorized" }, 401);
    }
  }
  if (!OPENAI_API_KEY) return json({ error: "OPENAI_API_KEY not set" }, 500);
  if (!SERVICE_KEY) return json({ error: "service key not set — add the RADAR_SERVICE_KEY secret" }, 500);
  const db = createClient(SUPABASE_URL, SERVICE_KEY);

  const [{ data: sources, error: srcErr }, { data: holidayRows }] = await Promise.all([
    db.from("sources").select("id, url, tier").eq("kind", "rss"),
    db.from("holidays").select("day"),
  ]);
  if (srcErr) return json({ error: srcErr.message, serviceKeyLen: SERVICE_KEY.length }, 500);
  if (!sources?.length) return json({ message: "no rss sources configured" }, 200);
  // Holidays failing isn't fatal — `dayAwareExpiry` still handles weekends.
  const holidaySet = new Set<string>((holidayRows ?? []).map((h: { day: string }) => h.day));

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
        const occurredAt = toISO(str(it.pubDate ?? it.published ?? it.updated)) ?? new Date().toISOString();
        items.push({
          title,
          body: clean(str(it.description ?? it["content:encoded"] ?? "")),
          link,
          occurredAt,
          expiresAt: dayAwareExpiry(occurredAt, holidaySet),
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
  // Skip items already past their day-aware expiry — no point spending an OpenAI
  // call to tag a story that would be expired the moment it's stored. Cap per run
  // so the first (all-fresh) invocation completes and upserts instead of timing out.
  const nowMs = Date.now();
  const allFresh = dedupeByLink(items)
    .filter((i) => !known.has(i.link) && Date.parse(i.expiresAt) > nowMs);
  const fresh = allFresh.slice(0, MAX_PER_RUN);

  // Tag + build rows.
  const rows = [];
  let tagFailures = 0;
  let dropped = 0;
  let firstTagError: string | null = null;
  for (const item of fresh) {
    const result = await tagItem(item);
    if ("error" in result) {
      tagFailures++;
      if (!firstTagError) firstTagError = result.error;
      continue;
    }
    const tag = result.tag;
    if (!tag.relevant) { dropped++; continue; } // no Argentine connection
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
      expires_at: item.expiresAt,
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
  let pushed = 0;
  if (rows.length) {
    // `.select()` after an ignore-duplicates upsert returns only the rows that
    // were actually inserted — exactly what we want to push for.
    const { data: insertedRows, error } = await db
      .from("news_events")
      .upsert(rows, { onConflict: "dedup_key", ignoreDuplicates: true })
      .select("id, headline, severity");
    if (error) return json({ error: error.message }, 500);
    inserted = insertedRows?.length ?? 0;
    const breaking = (insertedRows ?? []).filter((r: { severity: string }) => r.severity === "breaking");
    if (breaking.length) pushed = await pushBreaking(db, breaking);
  }
  return json({ feeds: sources.length, candidates: items.length, backlog: allFresh.length, processed: fresh.length, dropped, inserted, pushed, tagFailures, firstTagError }, 200);
});

// ── push (APNs) ──────────────────────────────────────────────────────────────
// Fan out a breaking-news alert to every registered device. Best-effort: a bad
// token (410) is pruned, anything else is skipped. Returns the count delivered.
// deno-lint-ignore no-explicit-any
async function pushBreaking(db: any, events: { id: string; headline: string }[]): Promise<number> {
  if (!APNS_KEY || !APNS_KEY_ID || !APNS_TEAM_ID || !APNS_TOPIC) return 0;
  const { data: tokens } = await db.from("device_tokens").select("token");
  if (!tokens?.length) return 0;
  let jwt: string;
  try { jwt = await apnsJWT(); } catch (_) { return 0; }

  let sent = 0;
  for (const ev of events) {
    const payload = JSON.stringify({
      aps: { alert: { title: "Urgente", body: ev.headline }, sound: "default" },
      eventId: ev.id,
    });
    for (const { token } of tokens as { token: string }[]) {
      try {
        const res = await fetch(`https://${APNS_HOST}/3/device/${token}`, {
          method: "POST",
          headers: {
            authorization: `bearer ${jwt}`,
            "apns-topic": APNS_TOPIC,
            "apns-push-type": "alert",
            "apns-priority": "10",
          },
          body: payload,
        });
        if (res.status === 200) sent++;
        else if (res.status === 410) await db.from("device_tokens").delete().eq("token", token);
        else await res.body?.cancel();
      } catch (_) { /* skip this token */ }
    }
  }
  return sent;
}

let cachedApnsJWT: { token: string; iat: number } | null = null;
async function apnsJWT(): Promise<string> {
  // APNs accepts a provider token for up to 60 min; reuse within the invocation.
  const now = Math.floor(Date.now() / 1000);
  if (cachedApnsJWT && now - cachedApnsJWT.iat < 3000) return cachedApnsJWT.token;
  const header = b64url(JSON.stringify({ alg: "ES256", kid: APNS_KEY_ID }));
  const payload = b64url(JSON.stringify({ iss: APNS_TEAM_ID, iat: now }));
  const signingInput = `${header}.${payload}`;
  const key = await importP8(APNS_KEY);
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(signingInput));
  const token = `${signingInput}.${b64urlBytes(new Uint8Array(sig))}`;
  cachedApnsJWT = { token, iat: now };
  return token;
}
async function importP8(pem: string): Promise<CryptoKey> {
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey("pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
}
function b64url(str: string): string {
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function b64urlBytes(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

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
// ART (Argentina) calendar components for a UTC timestamp. Argentina has been
// UTC-3 year-round since 2009, so we don't need a real timezone DB.
function artComponents(utcMs: number) {
  const shifted = new Date(utcMs + AR_OFFSET_HOURS * 3_600_000);
  return {
    y: shifted.getUTCFullYear(),
    m: shifted.getUTCMonth() + 1,
    d: shifted.getUTCDate(),
    wd: shifted.getUTCDay(), // 0=Sun … 6=Sat
    iso: shifted.toISOString().slice(0, 10),
  };
}
function endOfArtDay(y: number, m: number, d: number): string {
  // 23:59:59.999 ART = (23 - (-3)) = 26:59:59 UTC, which Date.UTC rolls into the next day.
  return new Date(Date.UTC(y, m - 1, d, 23 - AR_OFFSET_HOURS, 59, 59, 999)).toISOString();
}
/// Expiry = end of the next ART business day after the article (skipping
/// weekends + holidays). Starts the search 24h ahead so a Tuesday-afternoon
/// story doesn't expire later that same Tuesday.
function dayAwareExpiry(occurredAtIso: string, holidays: Set<string>): string {
  let t = Date.parse(occurredAtIso) + 24 * 3_600_000;
  for (let i = 0; i < 14; i++) { // hard cap so a bad seed can't infinite-loop
    const a = artComponents(t);
    const isWeekend = a.wd === 0 || a.wd === 6;
    if (!isWeekend && !holidays.has(a.iso)) return endOfArtDay(a.y, a.m, a.d);
    t += 24 * 3_600_000;
  }
  return new Date(Date.parse(occurredAtIso) + 24 * 3_600_000).toISOString();
}
async function tagItem(item: FeedItem): Promise<{ tag: Tag } | { error: string }> {
  const system = `Sos un editor de un mapa de noticias de Argentina. Devolvé SOLO el JSON pedido.
- relevant: true sólo si es periodismo informativo sobre Argentina o argentinos (incluye argentinos o equipos argentinos en el exterior, relaciones exteriores, ayuda argentina a otros países). FALSE si: (a) no tiene NINGUNA conexión con Argentina (p. ej. liga alemana sin argentinos, farándula de Hollywood); (b) es contenido promocional/no informativo aun siendo argentino: trivias o juegos ("jugá", "sumá puntos", "competí", "ganá un auto/premio/viaje"), sorteos, promos de suscripción o newsletter, publicidad nativa, contenido patrocinado, pushes de productos del propio medio.
- scope: "provincial" si ocurre en una provincia puntual; "national" si es de alcance nacional o internacional con ángulo argentino, sin una provincia puntual.
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
              required: ["relevant", "scope", "province", "category", "severity"],
              properties: {
                relevant: { type: "boolean" },
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
