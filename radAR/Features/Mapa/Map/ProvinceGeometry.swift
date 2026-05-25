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
    /// CABA is a geographic speck; the enclave — its own polygon plus the matching
    /// notch carved into Buenos Aires — is inflated by this factor around `cabaCenter`
    /// so the city is legible and the BA cutout stays aligned with it. Disproportionate
    /// on purpose. (Center + radius are tuned to this dataset's geometry: CABA's outline
    /// and BA's notch both sit within ~0.13°, BA's next coast point is ~0.22° out.)
    static let cabaInflation: Double = 2.0
    private static let cabaCenter = CLLocationCoordinate2D(latitude: -34.6483, longitude: -58.4377)
    private static let cabaEnclaveRadius: Double = 0.18

    static func load(in bundle: Bundle = .main) -> [ProvinceShape] {
        GeoJSONLoading.features(named: "argentina-provinces", in: bundle).compactMap { feature -> ProvinceShape? in
            guard
                let code = feature.properties?["code"] as? String,
                let province = ArgentineProvince(rawValue: code)
            else { return nil }

            let ringPositions = GeoJSONLoading.polygonRings(from: feature.geometry)
            guard !ringPositions.isEmpty else { return nil }

            let rings = ringPositions.map { ring in
                ring.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            }
            return makeShape(province: province, rings: rings)
        }
    }

    /// Builds a shape, inflating the CABA enclave for CABA + Buenos Aires so the city
    /// and its cutout render larger than their true (tiny) footprint and stay aligned.
    private static func makeShape(
        province: ArgentineProvince,
        rings rawRings: [[CLLocationCoordinate2D]]
    ) -> ProvinceShape {
        let inflates = province == .caba || province == .buenosAires
        var bounds = GeoBounds.empty
        let rings = rawRings.map { ring in
            ring.map { coord -> CLLocationCoordinate2D in
                let c = inflates ? inflateEnclave(coord) : coord
                bounds.extend(lat: c.latitude, lon: c.longitude)
                return c
            }
        }
        return ProvinceShape(province: province, rings: rings, bounds: bounds)
    }

    /// Scales a coordinate away from `cabaCenter` by `cabaInflation` when it falls
    /// inside the enclave radius — i.e. it's part of CABA's outline or BA's notch.
    private static func inflateEnclave(_ coord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let dLat = coord.latitude - cabaCenter.latitude
        let dLon = coord.longitude - cabaCenter.longitude
        guard (dLat * dLat + dLon * dLon) < cabaEnclaveRadius * cabaEnclaveRadius else { return coord }
        return CLLocationCoordinate2D(
            latitude: cabaCenter.latitude + dLat * cabaInflation,
            longitude: cabaCenter.longitude + dLon * cabaInflation
        )
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
