import Foundation

// TODO: replace with a live feed (cotizaciones BCRA + headlines stream).
enum MockTickerData {
    static let items: [TickerItem] = [
        .urgent("Conferencia presidencial 18:00 hs"),
        .quote(label: "Dólar oficial", value: "$1.245,00", change: "+0,3%"),
        .quote(label: "Dólar blue", value: "$1.345,00", change: "-1,2%"),
        .quote(label: "MEP", value: "$1.298,50", change: "+0,1%"),
        .quote(label: "CCL", value: "$1.310,75", change: "+0,5%"),
        .quote(label: "Merval", value: "1.842.300", change: "+1,8%"),
        .stat(label: "Riesgo país", value: "1.247 pb"),
        .urgent("Paro general confirmado para el jueves"),
        .stat(label: "BCRA reservas", value: "US$ 28,4B"),
        .quote(label: "Soja", value: "US$ 425,40", change: "+0,8%"),
        .quote(label: "Petróleo", value: "US$ 73,20", change: "-0,4%"),
        .urgent("Vuelve a sesionar el Senado a las 16 hs"),
    ]
}
