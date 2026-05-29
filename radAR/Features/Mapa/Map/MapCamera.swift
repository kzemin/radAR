import CoreLocation
import CoreGraphics
import Foundation

/// Lightweight equirectangular camera tuned for a country-sized view.
/// `zoom == 1` frames the whole Argentina extent inside the canvas with padding.
struct MapCamera: Equatable {
    var centerLat: Double
    var centerLon: Double
    var zoom: Double

    // Headroom below 1.0 so a national selection can pull the camera back into
    // a "looking at the whole country" overview, not just frame it edge-to-edge.
    static let minZoom: Double = 0.7
    static let maxZoom: Double = 8.0

    /// Reference extent (Argentina mainland + Tierra del Fuego) used as zoom = 1 baseline.
    static let referenceBounds = GeoBounds(
        minLat: -55.5,
        maxLat: -21.5,
        minLon: -73.8,
        maxLon: -53.5
    )

    /// Camera-center clamp envelope: mainland Argentina + Malvinas. Tighter than the
    /// projection's `referenceBounds` slack to keep the user inside Argentina.
    static let allowedBounds = GeoBounds(
        minLat: -56.5,
        maxLat: -20.5,
        minLon: -75.0,
        maxLon: -52.0
    )

    static let `default` = MapCamera(
        centerLat: referenceBounds.centerLat,
        centerLon: referenceBounds.centerLon,
        zoom: 1.0
    )

    static func camera(
        framing bounds: GeoBounds,
        canvasSize: CGSize,
        padding: CGFloat = 32
    ) -> MapCamera {
        let projection = MapProjection(
            camera: MapCamera(
                centerLat: bounds.centerLat,
                centerLon: bounds.centerLon,
                zoom: 1.0
            ),
            canvasSize: canvasSize
        )
        // Solve for zoom so the bounds span fits inside canvasSize - padding.
        let usableWidth = max(canvasSize.width - padding * 2, 1)
        let usableHeight = max(canvasSize.height - padding * 2, 1)
        let cosFactor = cos(bounds.centerLat * .pi / 180)
        let lonWidthInPoints = bounds.spanLon * cosFactor * projection.baseScale
        let latHeightInPoints = bounds.spanLat * projection.baseScale
        let zoomX = usableWidth / max(lonWidthInPoints, 1)
        let zoomY = usableHeight / max(latHeightInPoints, 1)
        let zoom = min(zoomX, zoomY).clamped(to: minZoom...maxZoom)
        return MapCamera(centerLat: bounds.centerLat, centerLon: bounds.centerLon, zoom: zoom)
    }

    mutating func clampToReference() {
        zoom = zoom.clamped(to: Self.minZoom...Self.maxZoom)
        let bounds = Self.allowedBounds
        let slack = 2.0 / zoom
        centerLat = centerLat.clamped(to: (bounds.minLat - slack)...(bounds.maxLat + slack))
        centerLon = centerLon.clamped(to: (bounds.minLon - slack)...(bounds.maxLon + slack))
    }
}

/// Plate-carrée projection with longitude cosine compression at the camera latitude.
struct MapProjection {
    let camera: MapCamera
    let canvasSize: CGSize
    let baseScale: CGFloat
    private let cosFactor: Double

    init(camera: MapCamera, canvasSize: CGSize) {
        self.camera = camera
        self.canvasSize = canvasSize

        let ref = MapCamera.referenceBounds
        let cosCenter = cos(ref.centerLat * .pi / 180)
        let refLonPoints = ref.spanLon * cosCenter
        let refLatPoints = ref.spanLat
        let fit = min(canvasSize.width / max(refLonPoints, 0.001), canvasSize.height / max(refLatPoints, 0.001))
        self.baseScale = CGFloat(fit) * 0.94 // small inset so the country never kisses the edge

        self.cosFactor = cos(camera.centerLat * .pi / 180)
    }

    var scale: CGFloat { baseScale * CGFloat(camera.zoom) }

    func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        let dx = (coordinate.longitude - camera.centerLon) * cosFactor
        let dy = (coordinate.latitude - camera.centerLat)
        let x = canvasSize.width / 2 + CGFloat(dx) * scale
        let y = canvasSize.height / 2 - CGFloat(dy) * scale
        return CGPoint(x: x, y: y)
    }

    func coordinate(for point: CGPoint) -> CLLocationCoordinate2D {
        let dxPoints = point.x - canvasSize.width / 2
        let dyPoints = canvasSize.height / 2 - point.y
        let lon = camera.centerLon + Double(dxPoints / scale) / cosFactor
        let lat = camera.centerLat + Double(dyPoints / scale)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func degreesPerPoint() -> (lat: Double, lon: Double) {
        let latPerPoint = 1.0 / Double(scale)
        let lonPerPoint = latPerPoint / cosFactor
        return (latPerPoint, lonPerPoint)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
