import Foundation

/// Source of live market quotes for the ticker. A best-effort fetch — partial
/// failures return whatever loaded so the ticker still has something to show.
protocol MarketService {
    func fetchQuotes() async -> [MarketQuote]
}

/// Aggregates Argentine market quotes from a handful of free public JSON APIs
/// with per-quote network fallbacks and a persistent `QuoteCache` as the final
/// safety net. Each fetch function also computes its own change column — from
/// the API's variation field when given, or from the cache's daily anchor
/// otherwise — so the ticker reads with red/green deltas on every quote that
/// has one.
struct DolarApiMarketService: MarketService {
    var session: URLSession = .shared
    var cache: QuoteCache = .shared

    func fetchQuotes() async -> [MarketQuote] {
        async let dollars = fetchDollarsLive()
        async let risk = fetchRiesgoPais()
        async let inflation = fetchInflacion()
        async let reservas = fetchBcraReservas()
        async let merval = fetchMerval()
        async let spx = fetchSPX()
        async let btc = fetchBTC()
        async let soja = fetchSoja()
        async let petroleo = fetchPetroleo()

        var live: [MarketQuote] = await dollars
        if let r = await risk { live.append(r) }
        if let i = await inflation { live.append(i) }
        if let r = await reservas { live.append(r) }
        if let m = await merval { live.append(m) }
        if let s = await spx { live.append(s) }
        if let b = await btc { live.append(b) }
        if let s = await soja { live.append(s) }
        if let p = await petroleo { live.append(p) }

        // Fill any gap (live nil + fallback nil) from the cache. Each successful
        // fetch already saved itself, so the cache here only serves the gaps.
        let liveKinds = Set(live.map(\.kind))
        var resolved = live
        for kind in MarketQuote.Kind.allCases where !liveKinds.contains(kind) {
            if let cached = cache.quote(for: kind) {
                resolved.append(cached)
            }
        }
        return resolved.sorted { Self.order[$0.kind, default: .max] < Self.order[$1.kind, default: .max] }
    }

    private static let order: [MarketQuote.Kind: Int] = Dictionary(uniqueKeysWithValues:
        MarketQuote.Kind.allCases.enumerated().map { ($1, $0) }
    )

    /// Wraps a freshly-fetched numeric in a `MarketQuote` with its change column
    /// computed and the result saved to the cache. `directPercent` is the daily
    /// change from the API itself (in % units, e.g. 2.51) when available;
    /// otherwise we fall back to the cache's daily anchor.
    private func makeQuote(
        kind: MarketQuote.Kind,
        display: String,
        numeric: Double,
        directPercent: Double? = nil
    ) -> MarketQuote {
        let pct: Double?
        if let direct = directPercent {
            pct = direct
        } else if let anchor = cache.anchor(for: kind), anchor > 0 {
            pct = ((numeric - anchor) / anchor) * 100
        } else {
            pct = nil
        }
        let change = pct.flatMap { Self.changePercent.format($0) }
        let quote = MarketQuote(kind: kind, value: display, change: change)
        cache.save(quote, numeric: numeric)
        return quote
    }

    // MARK: - Dollars

    /// Dollars: dolarapi is primary (gives all 5 types in one call), bluelytics
    /// is the fallback (oficial + blue, but rock-solid).
    private func fetchDollarsLive() async -> [MarketQuote] {
        let primary = await fetchDollarsFromDolarApi()
        if !primary.isEmpty { return primary }
        return await fetchDollarsFromBluelytics()
    }

    private func fetchDollarsFromDolarApi() async -> [MarketQuote] {
        guard let url = URL(string: "https://dolarapi.com/v1/dolares") else { return [] }
        do {
            let (data, _) = try await session.data(from: url)
            let rows = try JSONDecoder().decode([DolarRow].self, from: data)
            return rows.compactMap { row in
                guard let kind = kind(forCasa: row.casa), let venta = row.venta else { return nil }
                let display = dollarDisplay(kind: kind, compra: row.compra, venta: venta)
                // dolarapi exposes `variacion` only on a couple of casas — use it where present.
                return makeQuote(kind: kind, display: display, numeric: venta, directPercent: row.variacion)
            }
        } catch {
            return []
        }
    }

    private func fetchDollarsFromBluelytics() async -> [MarketQuote] {
        guard let url = URL(string: "https://api.bluelytics.com.ar/v2/latest") else { return [] }
        do {
            let (data, _) = try await session.data(from: url)
            let resp = try JSONDecoder().decode(BlueLyticsResponse.self, from: data)
            var out: [MarketQuote] = []
            if let v = resp.oficial.valueSell, v > 0 {
                let display = dollarDisplay(kind: .dolarOficial, compra: resp.oficial.valueBuy, venta: v)
                out.append(makeQuote(kind: .dolarOficial, display: display, numeric: v))
            }
            if let v = resp.blue.valueSell, v > 0 {
                let display = dollarDisplay(kind: .dolarBlue, compra: resp.blue.valueBuy, venta: v)
                out.append(makeQuote(kind: .dolarBlue, display: display, numeric: v))
            }
            return out
        } catch {
            return []
        }
    }

    /// Whether a dollar kind shows both compra/venta in the ticker. Argentine
    /// convention: oficial / blue / USDT are commonly quoted as a buy-sell pair;
    /// CCL is usually shown as a single mid-market rate.
    private static let dollarsShowingBuySell: Set<MarketQuote.Kind> = [
        .dolarOficial, .dolarBlue, .dolarUsdt
    ]

    private func dollarDisplay(kind: MarketQuote.Kind, compra: Double?, venta: Double) -> String {
        let ventaStr = Self.peso.format(venta)
        guard Self.dollarsShowingBuySell.contains(kind),
              let compra, compra > 0
        else { return ventaStr }
        return "C: \(Self.peso.format(compra)) | V: \(ventaStr)"
    }

    private func kind(forCasa casa: String) -> MarketQuote.Kind? {
        switch casa {
        case "oficial": .dolarOficial
        case "blue": .dolarBlue
        case "contadoconliqui": .dolarCcl
        case "cripto": .dolarUsdt
        default: nil
        }
    }

    // MARK: - Stats (no change column)

    private func fetchRiesgoPais() async -> MarketQuote? {
        guard let url = URL(string: "https://api.argentinadatos.com/v1/finanzas/indices/riesgo-pais") else { return nil }
        do {
            let (data, _) = try await session.data(from: url)
            let rows = try JSONDecoder().decode([RiskRow].self, from: data)
            guard let latest = rows.max(by: { $0.fecha < $1.fecha }) else { return nil }
            let quote = MarketQuote(kind: .riesgoPais, value: "\(Int(latest.valor.rounded())) pb")
            cache.save(quote)
            return quote
        } catch {
            return nil
        }
    }

    private func fetchInflacion() async -> MarketQuote? {
        guard let url = URL(string: "https://api.argentinadatos.com/v1/finanzas/indices/inflacion") else { return nil }
        do {
            let (data, _) = try await session.data(from: url)
            let rows = try JSONDecoder().decode([RiskRow].self, from: data)
            guard let latest = rows.max(by: { $0.fecha < $1.fecha }) else { return nil }
            let quote = MarketQuote(kind: .inflacion, value: Self.percent.format(latest.valor))
            cache.save(quote)
            return quote
        } catch {
            return nil
        }
    }

    /// BCRA's v4 public API exposes reservas as `idVariable 1` in millions of USD.
    private func fetchBcraReservas() async -> MarketQuote? {
        guard let url = URL(string: "https://api.bcra.gob.ar/estadisticas/v4.0/Monetarias/1?limit=1") else { return nil }
        do {
            let (data, _) = try await session.data(from: url)
            let resp = try JSONDecoder().decode(BcraResponse.self, from: data)
            guard let entry = resp.results.first?.detalle.first else { return nil }
            let quote = MarketQuote(kind: .bcraReservas, value: Self.billions.format(millions: entry.valor))
            cache.save(quote)
            return quote
        } catch {
            return nil
        }
    }

    // MARK: - Merval

    /// Primary: BYMA's own `free` open API (the actual exchange, source of truth).
    /// Fallback: Yahoo Finance v8 chart. Both expose a daily change so the
    /// change column is computed directly from the API, not from the cache.
    private func fetchMerval() async -> MarketQuote? {
        if let primary = await fetchMervalFromByma() { return primary }
        return await fetchMervalFromYahoo()
    }

    private func fetchMervalFromByma() async -> MarketQuote? {
        guard let url = URL(string: "https://open.bymadata.com.ar/vanoms-be-core/rest/api/bymadata/free/index-price") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (iPhone) radAR/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = Data("{}".utf8)
        do {
            let (data, _) = try await session.data(for: request)
            let resp = try JSONDecoder().decode(BymaIndexResponse.self, from: data)
            guard let row = resp.data.first(where: { $0.symbol == "M" }), row.price > 0 else { return nil }
            // BYMA's `variation` is a decimal fraction (0.0251 = 2.51%) — scale to percent.
            let direct = row.variation.map { $0 * 100 }
            return makeQuote(kind: .merval, display: Self.integer.format(row.price), numeric: row.price, directPercent: direct)
        } catch {
            return nil
        }
    }

    private func fetchMervalFromYahoo() async -> MarketQuote? {
        guard let pair = await yahooClose(symbol: "^MERV") else { return nil }
        let direct: Double? = pair.prev.flatMap { p in
            guard p > 0 else { return nil }
            return ((pair.close - p) / p) * 100
        }
        return makeQuote(kind: .merval, display: Self.integer.format(pair.close), numeric: pair.close, directPercent: direct)
    }

    // MARK: - Equities + crypto (Yahoo)

    /// S&P 500 index via Yahoo `^GSPC`. Rendered as a plain decimal (no currency
    /// prefix — it's an index level, not a USD price).
    private func fetchSPX() async -> MarketQuote? {
        guard let pair = await yahooClose(symbol: "^GSPC") else { return nil }
        let direct: Double? = pair.prev.flatMap { p in
            guard p > 0 else { return nil }
            return ((pair.close - p) / p) * 100
        }
        return makeQuote(kind: .spx, display: Self.decimal.format(pair.close), numeric: pair.close, directPercent: direct)
    }

    /// Bitcoin price in USD via Yahoo `BTC-USD`. Rendered to the dollar — the
    /// intraday change is in hundreds of USD, sub-dollar precision is noise.
    private func fetchBTC() async -> MarketQuote? {
        guard let pair = await yahooClose(symbol: "BTC-USD") else { return nil }
        let direct: Double? = pair.prev.flatMap { p in
            guard p > 0 else { return nil }
            return ((pair.close - p) / p) * 100
        }
        return makeQuote(kind: .btc, display: "US$" + Self.integer.format(pair.close), numeric: pair.close, directPercent: direct)
    }

    // MARK: - Commodities

    /// Soja: Stooq is primary, Yahoo `ZS=F` is the fallback. Both quote soybean
    /// futures in US¢/bushel; we convert to US$/tonne (36.7437 bu/tonne) to
    /// match the Argentine convention.
    private func fetchSoja() async -> MarketQuote? {
        var pair = await stooqClosePrev(symbol: "zs.f")
        if pair == nil { pair = await yahooClose(symbol: "ZS=F") }
        guard let pair else { return nil }
        let perTonne = pair.close * 36.7437 / 100.0
        let direct: Double? = pair.prev.flatMap { p in
            guard p > 0 else { return nil }
            let priorPerTonne = p * 36.7437 / 100.0
            return ((perTonne - priorPerTonne) / priorPerTonne) * 100
        }
        return makeQuote(kind: .soja, display: Self.dollar.format(perTonne), numeric: perTonne, directPercent: direct)
    }

    /// Petróleo (WTI): Stooq is primary, Yahoo `CL=F` is the fallback. Both in US$/barrel.
    private func fetchPetroleo() async -> MarketQuote? {
        var pair = await stooqClosePrev(symbol: "cl.f")
        if pair == nil { pair = await yahooClose(symbol: "CL=F") }
        guard let pair else { return nil }
        let direct: Double? = pair.prev.flatMap { p in
            guard p > 0 else { return nil }
            return ((pair.close - p) / p) * 100
        }
        return makeQuote(kind: .petroleo, display: Self.dollar.format(pair.close), numeric: pair.close, directPercent: direct)
    }

    // MARK: - Network helpers

    /// Latest close + previous close from Yahoo's v8 chart endpoint. Yahoo
    /// rejects empty UAs so we set a browser-shaped one.
    private func yahooClose(symbol: String) async -> (close: Double, prev: Double?)? {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? symbol
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1d") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone) radAR/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await session.data(for: request)
            let resp = try JSONDecoder().decode(YahooChart.self, from: data)
            guard let meta = resp.chart.result?.first?.meta else { return nil }
            return (meta.regularMarketPrice, meta.chartPreviousClose)
        } catch {
            return nil
        }
    }

    /// Latest close + previous close from Stooq's 1-row CSV endpoint (fields
    /// `sd2t2cp` → Symbol/Date/Time/Close/Prev). Returns nil for "N/D" rows.
    private func stooqClosePrev(symbol: String) async -> (close: Double, prev: Double?)? {
        guard let url = URL(string: "https://stooq.com/q/l/?s=\(symbol)&f=sd2t2cp&h&e=csv") else { return nil }
        do {
            let (data, _) = try await session.data(from: url)
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            let lines = text.split(whereSeparator: { $0.isNewline })
            guard lines.count >= 2 else { return nil }
            let cols = lines[1].split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard cols.count >= 4, let close = Double(cols[3]), close > 0 else { return nil }
            let prev: Double? = cols.count >= 5 ? Double(cols[4]) : nil
            return (close, prev)
        } catch {
            return nil
        }
    }

    // MARK: - Formatters

    private static let peso = PesoFormatter()
    private static let percent = PercentFormatter()
    private static let dollar = DollarFormatter()
    private static let billions = BillionFormatter()
    private static let integer = IntegerFormatter()
    private static let decimal = DecimalFormatter()
    private static let changePercent = ChangeFormatter()

    private struct PesoFormatter {
        let nf: NumberFormatter = {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "es_AR")
            // Decimal + manual "$" prefix avoids the locale's default
            // currency spacing ("$ 1.430,00") — we want "$1.430,00" flush.
            f.numberStyle = .decimal
            f.minimumFractionDigits = 2
            f.maximumFractionDigits = 2
            return f
        }()
        func format(_ value: Double) -> String {
            "$" + (nf.string(from: NSNumber(value: value)) ?? String(value))
        }
    }

    private struct PercentFormatter {
        let nf: NumberFormatter = {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "es_AR")
            f.minimumFractionDigits = 1
            f.maximumFractionDigits = 1
            return f
        }()
        func format(_ value: Double) -> String {
            (nf.string(from: NSNumber(value: value)) ?? String(value)) + "%"
        }
    }

    private struct DollarFormatter {
        let nf: NumberFormatter = {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "es_AR")
            f.numberStyle = .decimal
            f.minimumFractionDigits = 2
            f.maximumFractionDigits = 2
            return f
        }()
        func format(_ value: Double) -> String {
            "US$" + (nf.string(from: NSNumber(value: value)) ?? String(value))
        }
    }

    private struct BillionFormatter {
        let nf: NumberFormatter = {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "es_AR")
            f.minimumFractionDigits = 1
            f.maximumFractionDigits = 1
            return f
        }()
        /// `value` is in millions of USD (BCRA reservas convention); rendered as US$XX,YB.
        func format(millions value: Double) -> String {
            let billions = value / 1000.0
            return "US$" + (nf.string(from: NSNumber(value: billions)) ?? String(billions)) + "B"
        }
    }

    private struct IntegerFormatter {
        let nf: NumberFormatter = {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "es_AR")
            f.numberStyle = .decimal
            f.maximumFractionDigits = 0
            return f
        }()
        func format(_ value: Double) -> String {
            nf.string(from: NSNumber(value: value.rounded())) ?? String(Int(value.rounded()))
        }
    }

    /// Plain decimal with 2 places — no currency prefix. Used for index levels
    /// (S&P 500) where the number isn't a USD price.
    private struct DecimalFormatter {
        let nf: NumberFormatter = {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "es_AR")
            f.numberStyle = .decimal
            f.minimumFractionDigits = 2
            f.maximumFractionDigits = 2
            return f
        }()
        func format(_ value: Double) -> String {
            nf.string(from: NSNumber(value: value)) ?? String(value)
        }
    }

    /// Renders a percentage (e.g. 2.51) as "+2,51%" / "-1,3%". Returns nil for
    /// sub-0.05% values so the ticker doesn't show a confusing "+0,0%" badge
    /// when the value barely moved.
    private struct ChangeFormatter {
        let nf: NumberFormatter = {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "es_AR")
            f.minimumFractionDigits = 1
            f.maximumFractionDigits = 2
            return f
        }()
        func format(_ percent: Double) -> String? {
            guard percent.isFinite else { return nil }
            let rounded = (percent * 100).rounded() / 100
            if abs(rounded) < 0.05 { return nil }
            let formatted = nf.string(from: NSNumber(value: abs(rounded))) ?? String(abs(rounded))
            return (rounded < 0 ? "-" : "+") + formatted + "%"
        }
    }

    // MARK: - Decoders

    private struct DolarRow: Decodable {
        let casa: String
        let compra: Double?
        let venta: Double?
        let variacion: Double?
    }

    private struct RiskRow: Decodable {
        let fecha: String
        let valor: Double
    }

    private struct BlueLyticsResponse: Decodable {
        let oficial: BlueLyticsValue
        let blue: BlueLyticsValue
    }
    private struct BlueLyticsValue: Decodable {
        let valueSell: Double?
        let valueBuy: Double?
        enum CodingKeys: String, CodingKey {
            case valueSell = "value_sell"
            case valueBuy = "value_buy"
        }
    }

    private struct BcraResponse: Decodable {
        let results: [BcraResult]
    }
    private struct BcraResult: Decodable {
        let detalle: [BcraEntry]
    }
    private struct BcraEntry: Decodable {
        let fecha: String
        let valor: Double
    }

    private struct YahooChart: Decodable {
        let chart: ChartContainer
        struct ChartContainer: Decodable { let result: [Result]? }
        struct Result: Decodable { let meta: Meta }
        struct Meta: Decodable {
            let regularMarketPrice: Double
            let chartPreviousClose: Double?
        }
    }

    private struct BymaIndexResponse: Decodable {
        let data: [BymaIndex]
    }
    private struct BymaIndex: Decodable {
        let symbol: String
        let price: Double
        /// BYMA returns the daily change as a decimal fraction (0.0251 = 2.51%).
        let variation: Double?
    }
}
