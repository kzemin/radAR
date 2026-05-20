import CoreLocation
import SwiftUI

struct ArgentinaMapCanvas: View {
    let provinces: [ProvinceShape]
    let argentinaExtras: [BackdropShape]
    let worldCountries: [BackdropShape]
    let events: [NewsEvent]
    let activeProvinces: Set<ArgentineProvince>
    let selectedEventID: NewsEvent.ID?
    let cameraTargetCoordinate: CLLocationCoordinate2D?
    let cameraNonce: Int
    let onSelectEvent: (NewsEvent) -> Void
    let onTapEmpty: () -> Void

    @State private var camera: MapCamera = .default
    @State private var dragStartCamera: MapCamera?
    @State private var pinchStartZoom: Double?
    @State private var canvasSize: CGSize = .zero

    // Hand-rolled camera fly: SwiftUI can't interpolate MapCamera inside a Canvas
    // closure, so we drive smooth transitions via TimelineView + elapsed-time easing.
    @State private var flightSource: MapCamera?
    @State private var flightStart: Date = .distantPast

    private let pinSize: CGFloat = 12
    private let selectedPinSize: CGFloat = 18
    private let pinHitRadius: CGFloat = 26
    /// Minimum screen-space distance (points) between two rendered pins. Pins
    /// closer than this to a previously placed pin get suppressed at the current
    /// zoom so the map doesn't turn into a clump. Zooming in spaces pins out and
    /// they reappear automatically. Selected + breaking pins win priority.
    private let minPinSpacing: CGFloat = 28

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            TimelineView(.animation(paused: flightSource == nil)) { context in
                let renderCamera = displayedCamera(at: context.date)

                Canvas { ctx, drawSize in
                    let projection = MapProjection(camera: renderCamera, canvasSize: drawSize)
                    drawBackground(context: &ctx, size: drawSize)
                    drawGraticule(context: &ctx, projection: projection)
                    drawWorld(context: &ctx, projection: projection)
                    drawArgentinaExtras(context: &ctx, projection: projection)
                    drawProvinces(context: &ctx, projection: projection)
                    drawPins(context: &ctx, projection: projection)
                }
            }
            .contentShape(Rectangle())
            .gesture(tapGesture)
            .simultaneousGesture(panGesture)
            .simultaneousGesture(zoomGesture)
            .onChange(of: size) { _, newSize in
                canvasSize = newSize
            }
            .onAppear {
                canvasSize = size
            }
            .onChange(of: cameraNonce) { _, _ in
                startFlight()
            }
        }
    }

    /// Returns the camera that should be rendered right now: interpolated if a
    /// flight is mid-air, otherwise the canonical `camera` state.
    private func displayedCamera(at date: Date) -> MapCamera {
        guard let source = flightSource else { return camera }
        let duration = RadarTheme.Animation.cameraFlyDuration
        let elapsed = date.timeIntervalSince(flightStart)
        guard elapsed >= 0, elapsed < duration else { return camera }
        let t = elapsed / duration
        let eased = 0.5 - 0.5 * cos(t * .pi)   // cosine ease-in-out
        return MapCamera(
            centerLat: source.centerLat + (camera.centerLat - source.centerLat) * eased,
            centerLon: source.centerLon + (camera.centerLon - source.centerLon) * eased,
            zoom: source.zoom + (camera.zoom - source.zoom) * eased
        )
    }

    /// Aborts any in-flight transition by snapping `camera` to the currently
    /// displayed position. Called when a gesture takes over.
    private func cancelFlight() {
        guard flightSource != nil else { return }
        camera = displayedCamera(at: Date())
        flightSource = nil
    }

    private var tapGesture: some Gesture {
        SpatialTapGesture(coordinateSpace: .local).onEnded { value in
            handleTap(at: value.location)
        }
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                guard canvasSize != .zero else { return }
                if dragStartCamera == nil {
                    cancelFlight()
                    dragStartCamera = camera
                }
                guard let start = dragStartCamera else { return }
                let projection = MapProjection(camera: start, canvasSize: canvasSize)
                let perPoint = projection.degreesPerPoint()
                var next = start
                next.centerLon -= Double(value.translation.width) * perPoint.lon
                next.centerLat += Double(value.translation.height) * perPoint.lat
                next.clampToReference()
                camera = next
            }
            .onEnded { _ in dragStartCamera = nil }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if pinchStartZoom == nil {
                    cancelFlight()
                    pinchStartZoom = camera.zoom
                }
                guard let start = pinchStartZoom else { return }
                var next = camera
                next.zoom = (start * Double(value.magnification))
                    .clamped(to: MapCamera.minZoom...MapCamera.maxZoom)
                next.clampToReference()
                camera = next
            }
            .onEnded { _ in pinchStartZoom = nil }
    }

    // MARK: - Drawing

    private func drawBackground(context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(rect), with: .color(MapaTheme.Colors.background))
    }

    private func drawGraticule(context: inout GraphicsContext, projection: MapProjection) {
        let style = StrokeStyle(lineWidth: 0.5, dash: [1.5, 4])
        let color = MapaTheme.Colors.mapGraticule
        let ref = MapCamera.referenceBounds
        let padding = 6.0

        let firstLat = Int((ref.minLat - padding).rounded(.down))
        let lastLat = Int((ref.maxLat + padding).rounded(.up))
        for lat in stride(from: firstLat, through: lastLat, by: 2) {
            var path = Path()
            let p0 = projection.point(for: .init(latitude: Double(lat), longitude: ref.minLon - padding))
            let p1 = projection.point(for: .init(latitude: Double(lat), longitude: ref.maxLon + padding))
            path.move(to: p0)
            path.addLine(to: p1)
            context.stroke(path, with: .color(color), style: style)
        }

        let firstLon = Int((ref.minLon - padding).rounded(.down))
        let lastLon = Int((ref.maxLon + padding).rounded(.up))
        for lon in stride(from: firstLon, through: lastLon, by: 2) {
            var path = Path()
            let p0 = projection.point(for: .init(latitude: ref.minLat - padding, longitude: Double(lon)))
            let p1 = projection.point(for: .init(latitude: ref.maxLat + padding, longitude: Double(lon)))
            path.move(to: p0)
            path.addLine(to: p1)
            context.stroke(path, with: .color(color), style: style)
        }
    }

    private func drawWorld(context: inout GraphicsContext, projection: MapProjection) {
        let fill = MapaTheme.Colors.mapWorldLand
        let stroke = MapaTheme.Colors.mapWorldBorder
        for shape in worldCountries {
            let path = projectedBackdropPath(for: shape, projection: projection)
            context.fill(path, with: .color(fill))
            context.stroke(path, with: .color(stroke), lineWidth: 0.6)
        }
    }

    private func drawArgentinaExtras(context: inout GraphicsContext, projection: MapProjection) {
        let fill = MapaTheme.Colors.mapLand
        let stroke = MapaTheme.Colors.mapBorder
        for shape in argentinaExtras {
            let path = projectedBackdropPath(for: shape, projection: projection)
            context.fill(path, with: .color(fill))
            context.stroke(path, with: .color(stroke), lineWidth: 0.8)
        }
    }

    private func projectedBackdropPath(for shape: BackdropShape, projection: MapProjection) -> Path {
        var path = Path()
        for ring in shape.rings {
            guard let first = ring.first else { continue }
            path.move(to: projection.point(for: first))
            for coord in ring.dropFirst() {
                path.addLine(to: projection.point(for: coord))
            }
            path.closeSubpath()
        }
        return path
    }

    private func drawProvinces(context: inout GraphicsContext, projection: MapProjection) {
        let selectedProvince = events.first(where: { $0.id == selectedEventID })?.province
        let strokeWidth: CGFloat = 0.8
        let selectedStrokeWidth: CGFloat = 1.5
        let landFill = MapaTheme.Colors.mapLand
        let activeFill = MapaTheme.Colors.mapActiveFill

        var selectedPath: Path?

        for shape in provinces {
            let path = projectedPath(for: shape, projection: projection)
            let isActive = activeProvinces.contains(shape.province)
            let isSelected = selectedProvince == shape.province

            // base land fill so the country reads as a solid silhouette
            context.fill(path, with: .color(landFill))

            if !isSelected, isActive {
                context.fill(path, with: .color(activeFill))
            }

            if isSelected {
                selectedPath = path
            } else {
                context.stroke(path, with: .color(MapaTheme.Colors.mapBorder), lineWidth: strokeWidth)
            }
        }

        // Render the selected province last so its halo sits above neighboring strokes.
        if let selectedPath {
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: MapaTheme.Colors.accent.opacity(0.65), radius: 4, x: 0, y: 0))
                layer.stroke(selectedPath, with: .color(MapaTheme.Colors.mapBorderSelected), lineWidth: selectedStrokeWidth)
            }
        }
    }

    private func drawPins(context: inout GraphicsContext, projection: MapProjection) {
        let prioritized = events.sorted { lhs, rhs in
            let lhsSelected = lhs.id == selectedEventID
            let rhsSelected = rhs.id == selectedEventID
            if lhsSelected != rhsSelected { return lhsSelected }

            let lhsBreaking = lhs.severity == .breaking
            let rhsBreaking = rhs.severity == .breaking
            if lhsBreaking != rhsBreaking { return lhsBreaking }

            return lhs.timestamp > rhs.timestamp
        }

        let minDistanceSq = minPinSpacing * minPinSpacing
        var placedPoints: [CGPoint] = []

        for event in prioritized {
            let point = projection.point(for: event.coordinate)

            let tooClose = placedPoints.contains { existing in
                let dx = existing.x - point.x
                let dy = existing.y - point.y
                return (dx * dx + dy * dy) < minDistanceSq
            }
            if tooClose { continue }
            placedPoints.append(point)

            let isSelected = event.id == selectedEventID
            let isBreaking = event.severity == .breaking
            let size = isSelected ? selectedPinSize : pinSize

            let rect = CGRect(
                x: point.x - size / 2,
                y: point.y - size / 2,
                width: size,
                height: size
            )
            let pinPath = Path(rect)

            let fill: Color
            let stroke: Color
            let strokeWidth: CGFloat

            if isSelected {
                fill = MapaTheme.Colors.accent
                stroke = MapaTheme.Colors.textPrimary
                strokeWidth = 1.5
            } else if isBreaking {
                fill = MapaTheme.Colors.accent
                stroke = MapaTheme.Colors.background
                strokeWidth = 1
            } else {
                fill = MapaTheme.Colors.pinNormal
                stroke = MapaTheme.Colors.background
                strokeWidth = 1
            }

            context.fill(pinPath, with: .color(fill))
            context.stroke(pinPath, with: .color(stroke), lineWidth: strokeWidth)
        }
    }

    private func projectedPath(for shape: ProvinceShape, projection: MapProjection) -> Path {
        var path = Path()
        for ring in shape.rings {
            guard let first = ring.first else { continue }
            path.move(to: projection.point(for: first))
            for coord in ring.dropFirst() {
                path.addLine(to: projection.point(for: coord))
            }
            path.closeSubpath()
        }
        return path
    }

    // MARK: - Interaction

    private func handleTap(at location: CGPoint) {
        guard canvasSize != .zero else { return }
        let projection = MapProjection(camera: camera, canvasSize: canvasSize)

        let hit = events
            .map { event -> (NewsEvent, CGFloat) in
                let p = projection.point(for: event.coordinate)
                let dx = p.x - location.x
                let dy = p.y - location.y
                return (event, sqrt(dx * dx + dy * dy))
            }
            .filter { $0.1 <= pinHitRadius }
            .min(by: { $0.1 < $1.1 })

        if let hit {
            onSelectEvent(hit.0)
            return
        }

        let tappedCoord = projection.coordinate(for: location)
        if let province = province(containing: tappedCoord),
           let event = events.first(where: { $0.province == province }) {
            onSelectEvent(event)
            return
        }

        onTapEmpty()
    }

    private func province(containing coordinate: CLLocationCoordinate2D) -> ArgentineProvince? {
        for shape in provinces {
            for ring in shape.rings where pointInRing(coordinate, ring: ring) {
                return shape.province
            }
        }
        return nil
    }

    private func pointInRing(_ point: CLLocationCoordinate2D, ring: [CLLocationCoordinate2D]) -> Bool {
        guard ring.count >= 3 else { return false }
        var inside = false
        var j = ring.count - 1
        for i in 0..<ring.count {
            let xi = ring[i].longitude, yi = ring[i].latitude
            let xj = ring[j].longitude, yj = ring[j].latitude
            let intersects = ((yi > point.latitude) != (yj > point.latitude))
                && (point.longitude < (xj - xi) * (point.latitude - yi) / ((yj - yi) == 0 ? .leastNonzeroMagnitude : (yj - yi)) + xi)
            if intersects { inside.toggle() }
            j = i
        }
        return inside
    }

    private func startFlight() {
        let target: MapCamera
        if let coord = cameraTargetCoordinate {
            var next = MapCamera(
                centerLat: coord.latitude,
                centerLon: coord.longitude,
                zoom: max(camera.zoom, 2.6)
            )
            next.clampToReference()
            target = next
        } else {
            target = .default
        }

        // Whatever the user sees right now becomes the flight's starting frame.
        // If a previous flight is mid-air, we resume from its interpolated position.
        let source = displayedCamera(at: Date())
        flightSource = source
        camera = target
        let startDate = Date()
        flightStart = startDate

        // Pause TimelineView once we've crossed the duration.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(RadarTheme.Animation.cameraFlyDuration + 0.05))
            // Only clear if this flight is still the active one.
            if flightStart == startDate {
                flightSource = nil
            }
        }
    }
}
