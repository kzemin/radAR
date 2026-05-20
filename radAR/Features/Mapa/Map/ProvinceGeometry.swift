import CoreLocation
import Foundation
import GeoJSONKit

struct ProvinceShape: Identifiable {
    let province: ArgentineProvince
    /// One or more closed rings. Provinces with islands or detached parts
    /// (Buenos Aires, Tierra del Fuego) contribute multiple rings.
    let rings: [[CLLocationCoordinate2D]]
    let bounds: GeoBounds

    var id: ArgentineProvince { province }
}

struct GeoBounds: Hashable {
    var minLat: Double
    var maxLat: Double
    var minLon: Double
    var maxLon: Double

    var centerLat: Double { (minLat + maxLat) / 2 }
    var centerLon: Double { (minLon + maxLon) / 2 }
    var spanLat: Double { maxLat - minLat }
    var spanLon: Double { maxLon - minLon }

    static let empty = GeoBounds(
        minLat: .infinity,
        maxLat: -.infinity,
        minLon: .infinity,
        maxLon: -.infinity
    )

    mutating func extend(lat: Double, lon: Double) {
        if lat < minLat { minLat = lat }
        if lat > maxLat { maxLat = lat }
        if lon < minLon { minLon = lon }
        if lon > maxLon { maxLon = lon }
    }

    mutating func union(_ other: GeoBounds) {
        if other.minLat < minLat { minLat = other.minLat }
        if other.maxLat > maxLat { maxLat = other.maxLat }
        if other.minLon < minLon { minLon = other.minLon }
        if other.maxLon > maxLon { maxLon = other.maxLon }
    }
}

enum ProvinceGeometryLoader {
    static func load(in bundle: Bundle = .main) -> [ProvinceShape] {
        GeoJSONLoading.features(named: "argentina-provinces", in: bundle).compactMap { feature in
            guard
                let code = feature.properties?["code"] as? String,
                let province = ArgentineProvince(rawValue: code)
            else { return nil }

            let ringPositions = GeoJSONLoading.polygonRings(from: feature.geometry)
            guard !ringPositions.isEmpty else { return nil }

            var bounds = GeoBounds.empty
            let rings: [[CLLocationCoordinate2D]] = ringPositions.map { ring in
                ring.map { position in
                    bounds.extend(lat: position.latitude, lon: position.longitude)
                    return CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
                }
            }

            return ProvinceShape(province: province, rings: rings, bounds: bounds)
        }
    }

    static var countryBounds: GeoBounds {
        var result = GeoBounds.empty
        for shape in load() {
            result.union(shape.bounds)
        }
        return result
    }
}

/// Non-clickable polygons rendered as backdrop or extra Argentine territory.
struct BackdropShape: Identifiable {
    let id: String
    let name: String
    let rings: [[CLLocationCoordinate2D]]
}

enum ExtrasGeometryLoader {
    static func load(in bundle: Bundle = .main) -> [BackdropShape] {
        GeoJSONLoading.backdrop(named: "argentina-extras", in: bundle)
    }
}

enum WorldGeometryLoader {
    static func load(in bundle: Bundle = .main) -> [BackdropShape] {
        GeoJSONLoading.backdrop(named: "world-other-countries", in: bundle)
    }
}

private enum GeoJSONLoading {
    static func features(named resource: String, in bundle: Bundle) -> [GeoJSON.Feature] {
        guard
            let url = bundle.url(forResource: resource, withExtension: "geojson"),
            let data = try? Data(contentsOf: url),
            let parsed = try? GeoJSON(data: data)
        else {
            assertionFailure("Missing or invalid \(resource).geojson")
            return []
        }

        if case .featureCollection(let features) = parsed.object {
            return features
        }
        return []
    }

    static func backdrop(named resource: String, in bundle: Bundle) -> [BackdropShape] {
        features(named: resource, in: bundle).flatMap { feature -> [BackdropShape] in
            let props = feature.properties ?? [:]
            let baseID = (props["code"] as? String)
                ?? (props["id"] as? String)
                ?? resource
            let baseName = (props["name"] as? String) ?? baseID

            let ringPositions = polygonRings(from: feature.geometry)
            return ringPositions.enumerated().compactMap { index, ring in
                guard ring.count >= 3 else { return nil }
                let coords = ring.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                }
                let id = ringPositions.count > 1 ? "\(baseID)-\(index)" : baseID
                return BackdropShape(id: id, name: baseName, rings: [coords])
            }
        }
    }

    /// Extracts each polygon's exterior ring. Holes (interiors) are ignored —
    /// none of our admin-level data uses them and we'd want to render them as
    /// separate cutouts if it did.
    static func polygonRings(from geometry: GeoJSON.GeometryObject) -> [[GeoJSON.Position]] {
        switch geometry {
        case .single(.polygon(let polygon)):
            return [polygon.exterior.positions]

        case .multi(let geometries):
            return geometries.compactMap { geometry in
                if case .polygon(let polygon) = geometry {
                    return polygon.exterior.positions
                }
                return nil
            }

        default:
            return []
        }
    }
}
