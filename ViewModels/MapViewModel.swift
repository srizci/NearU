//
//  MapViewModel.swift
//  NearU
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

enum NearbyCategory: String, CaseIterable, Identifiable {
    case restaurant = "Restoran"
    case cafe = "Kafe"
    case hospital = "Hastane"
    case pharmacy = "Eczane"
    case gasStation = "Benzinlik"
    case hotel = "Otel"

    var id: String { rawValue }
    var query: String { rawValue }

    var iconName: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .hospital: return "cross.case.fill"
        case .pharmacy: return "pills.fill"
        case .gasStation: return "fuelpump.fill"
        case .hotel: return "bed.double.fill"
        }
    }
}

enum LoopRouteDistance: Double, CaseIterable, Identifiable {
    case fiveHundred = 500
    case oneKm = 1000
    case twoKm = 2000

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .fiveHundred: return "500 m"
        case .oneKm: return "1 km"
        case .twoKm: return "2 km"
        }
    }
}

final class MapViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedPlace: PlaceItem?
    @Published var places: [PlaceItem] = []
    @Published var favorites: [PlaceItem] = []
    @Published var selectedTransportType: TransportType = .automobile
    @Published var activeCategory: NearbyCategory?

    @Published var route: MKRoute?
    @Published var routeParts: [MKRoute] = []

    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showErrorAlert: Bool = false

    @Published var selectedLoopDistance: LoopRouteDistance = .fiveHundred
    @Published var isLoopRouteMode: Bool = false
    @Published var loopTargetDistanceText: String = ""

    @Published var routeStepTexts: [String] = []
    @Published var previewDestinationName: String = ""
    @Published var isShowingRoutePreview: Bool = false
    @Published var isNavigating: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var currentInstruction: String = ""
    @Published var currentStepDistanceText: String = ""
    @Published var remainingRouteDistanceText: String = ""
    @Published var remainingRouteTimeText: String = ""
    @Published var hasArrived: Bool = false

    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.8746, longitude: 32.4932),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    let locationService = LocationService()

    private let favoritesKey = "NearU_Favorites"
    private var cancellables = Set<AnyCancellable>()
    private var didCenterOnUserOnce = false
    private var navigationDestination: CLLocationCoordinate2D?

    init() {
        bindLocation()
        loadFavorites()
        locationService.requestPermission()
    }

    func startLocationUpdates() {
        locationService.startUpdatingLocation()
    }

    private func bindLocation() {
        locationService.$userLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }

                if !self.didCenterOnUserOnce {
                    self.region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    self.didCenterOnUserOnce = true
                }

                if self.isNavigating {
                    self.updateNavigationProgress(with: location)
                }
            }
            .store(in: &cancellables)
    }

    func centerMapOnUser() {
        guard let coordinate = locationService.userLocation?.coordinate else {
            showError("Önce konum izni vermen gerekiyor.")
            return
        }

        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }

    func zoomIn() {
        region = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: max(region.span.latitudeDelta * 0.5, 0.002),
                longitudeDelta: max(region.span.longitudeDelta * 0.5, 0.002)
            )
        )
    }

    func zoomOut() {
        region = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: min(region.span.latitudeDelta * 2.0, 100),
                longitudeDelta: min(region.span.longitudeDelta * 2.0, 100)
            )
        )
    }

    func searchPlaces() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            places = []
            selectedPlace = nil
            clearRoute()
            return
        }

        activeCategory = nil
        performSearch(query: trimmed)
    }

    func searchNearby(category: NearbyCategory) {
        activeCategory = category
        searchText = category.query
        performSearch(query: category.query)
    }

    private func performSearch(query: String) {
        isLoading = true
        clearRoute()
        selectedPlace = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        MKLocalSearch(request: request).start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                if let error {
                    self.showError("Arama hatası: \(error.localizedDescription)")
                    return
                }

                guard let response else {
                    self.showError("Sonuç bulunamadı.")
                    return
                }

                self.places = response.mapItems.map { item in
                    PlaceItem(
                        name: item.name ?? "Bilinmeyen Yer",
                        coordinate: item.placemark.coordinate,
                        address: self.composeAddress(from: item.placemark),
                        category: item.pointOfInterestCategory?.rawValue
                    )
                }

                if self.places.isEmpty {
                    self.showError("Bu aramaya uygun yer bulunamadı.")
                    return
                }

                if let firstPlace = self.places.first {
                    self.selectPlace(firstPlace)
                }
            }
        }
    }

    func selectPlace(_ place: PlaceItem) {
        selectedPlace = place
        region = MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }

    func selectPlaceFromMapTap(at coordinate: CLLocationCoordinate2D) {
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
        request.resultTypes = .pointOfInterest

        MKLocalSearch(request: request).start { [weak self] response, _ in
            guard let self else { return }
            guard let items = response?.mapItems, !items.isEmpty else { return }

            let tappedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            let nearestItem = items.min { first, second in
                let firstLoc = CLLocation(latitude: first.placemark.coordinate.latitude, longitude: first.placemark.coordinate.longitude)
                let secondLoc = CLLocation(latitude: second.placemark.coordinate.latitude, longitude: second.placemark.coordinate.longitude)
                return tappedLocation.distance(from: firstLoc) < tappedLocation.distance(from: secondLoc)
            }

            guard let item = nearestItem else { return }

            let itemLocation = CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
            if tappedLocation.distance(from: itemLocation) > 50 { return }

            let place = PlaceItem(
                name: item.name ?? "Bilinmeyen Yer",
                coordinate: item.placemark.coordinate,
                address: self.composeAddress(from: item.placemark),
                category: item.pointOfInterestCategory?.rawValue
            )

            DispatchQueue.main.async {
                self.selectedPlace = place
            }
        }
    }

    func calculateRoute() {
        guard let userCoordinate = locationService.userLocation?.coordinate else {
            showError("Rota oluşturmak için kullanıcı konumu gerekli.")
            return
        }

        guard let selectedPlace else {
            showError("Önce bir yer seçmelisin.")
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: selectedPlace.coordinate))
        request.transportType = selectedTransportType.mkType
        request.requestsAlternateRoutes = false

        isLoading = true

        MKDirections(request: request).calculate { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                if let error {
                    self.showError("Rota oluşturulamadı: \(error.localizedDescription)")
                    return
                }

                guard let route = response?.routes.first else {
                    self.showError("Bu konum için rota bulunamadı.")
                    return
                }

                self.route = route
                self.routeParts = [route]
                self.isLoopRouteMode = false
                self.loopTargetDistanceText = ""
                self.previewDestinationName = selectedPlace.name
                self.navigationDestination = selectedPlace.coordinate
                self.routeStepTexts = self.cleanStepTexts(from: [route])
                self.isShowingRoutePreview = true
                self.isNavigating = false
                self.hasArrived = false
                self.currentStepIndex = 0
                self.selectedPlace = nil
                self.places = []
                self.updateRemainingRouteInfo()
            }
        }
    }

    func calculateLoopRoute() {
        guard let start = locationService.userLocation?.coordinate else {
            showError("Döngüsel rota için kullanıcı konumu gerekli.")
            return
        }

        clearRoute()
        isLoading = true

        let targetDistance = selectedLoopDistance.rawValue
        let radius = max(targetDistance / 4.0, 120)

        let pointA = coordinate(from: start, distanceMeters: radius, bearingDegrees: 45)
        let pointB = coordinate(from: start, distanceMeters: radius, bearingDegrees: 135)

        calculateRouteSegment(from: start, to: pointA) { [weak self] firstRoute in
            guard let self else { return }

            guard let firstRoute else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showError("Koşu/yürüyüş rotasının ilk bölümü oluşturulamadı.")
                }
                return
            }

            self.calculateRouteSegment(from: pointA, to: pointB) { secondRoute in
                guard let secondRoute else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.showError("Koşu/yürüyüş rotasının ikinci bölümü oluşturulamadı.")
                    }
                    return
                }

                self.calculateRouteSegment(from: pointB, to: start) { thirdRoute in
                    DispatchQueue.main.async {
                        self.isLoading = false

                        guard let thirdRoute else {
                            self.showError("Koşu/yürüyüş rotasının dönüş bölümü oluşturulamadı.")
                            return
                        }

                        let routes = [firstRoute, secondRoute, thirdRoute]
                        self.routeParts = routes
                        self.route = firstRoute
                        self.isLoopRouteMode = true
                        self.loopTargetDistanceText = self.formattedDistance(targetDistance)
                        self.previewDestinationName = "Döngüsel Koşu/Yürüyüş Rotası"
                        self.navigationDestination = start
                        self.routeStepTexts = self.cleanStepTexts(from: routes)
                        self.isShowingRoutePreview = true
                        self.isNavigating = false
                        self.hasArrived = false
                        self.currentStepIndex = 0
                        self.selectedPlace = nil
                        self.places = []
                        self.remainingRouteDistanceText = self.formattedDistance(self.totalRouteDistance())
                        self.remainingRouteTimeText = self.formattedTravelTime(self.totalRouteTime())
                    }
                }
            }
        }
    }

    private func calculateRouteSegment(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        completion: @escaping (MKRoute?) -> Void
    ) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking
        request.requestsAlternateRoutes = false

        MKDirections(request: request).calculate { response, error in
            if error != nil {
                completion(nil)
                return
            }

            completion(response?.routes.first)
        }
    }

    private func coordinate(
        from coordinate: CLLocationCoordinate2D,
        distanceMeters: CLLocationDistance,
        bearingDegrees: Double
    ) -> CLLocationCoordinate2D {
        let earthRadius = 6_371_000.0
        let bearing = bearingDegrees * .pi / 180

        let lat1 = coordinate.latitude * .pi / 180
        let lon1 = coordinate.longitude * .pi / 180

        let lat2 = asin(
            sin(lat1) * cos(distanceMeters / earthRadius) +
            cos(lat1) * sin(distanceMeters / earthRadius) * cos(bearing)
        )

        let lon2 = lon1 + atan2(
            sin(bearing) * sin(distanceMeters / earthRadius) * cos(lat1),
            cos(distanceMeters / earthRadius) - sin(lat1) * sin(lat2)
        )

        return CLLocationCoordinate2D(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
    }

    func startNavigation() {
        guard !routeParts.isEmpty else {
            showError("Önce rota oluşturmalısın.")
            return
        }

        let validSteps = navigableSteps()

        if validSteps.isEmpty {
            showError("Navigasyon adımları bulunamadı.")
            return
        }

        isShowingRoutePreview = false
        isNavigating = true
        hasArrived = false
        currentStepIndex = 0
        updateCurrentInstruction()

        if let userLocation = locationService.userLocation {
            updateNavigationProgress(with: userLocation)
        }
    }

    func stopNavigation() {
        isNavigating = false
        hasArrived = false
        currentStepIndex = 0
        currentInstruction = ""
        currentStepDistanceText = ""
    }

    func clearRoute() {
        route = nil
        routeParts = []
        routeStepTexts = []
        previewDestinationName = ""
        isShowingRoutePreview = false
        isNavigating = false
        currentStepIndex = 0
        currentInstruction = ""
        currentStepDistanceText = ""
        remainingRouteDistanceText = ""
        remainingRouteTimeText = ""
        hasArrived = false
        navigationDestination = nil
        isLoopRouteMode = false
        loopTargetDistanceText = ""
    }

    private func updateNavigationProgress(with userLocation: CLLocation) {
        guard !routeParts.isEmpty else { return }

        if let destination = navigationDestination {
            let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
            let destinationDistance = userLocation.distance(from: destinationLocation)

            if destinationDistance <= 25 && currentStepIndex >= max(navigableSteps().count - 2, 0) {
                hasArrived = true
                isNavigating = false
                currentInstruction = isLoopRouteMode ? "Döngüsel rota tamamlandı" : "Varış noktasına ulaştın"
                currentStepDistanceText = ""
                remainingRouteDistanceText = "0 m"
                remainingRouteTimeText = "0 dk"
                return
            }
        }

        let steps = navigableSteps()
        guard !steps.isEmpty else { return }

        if currentStepIndex >= steps.count {
            currentStepIndex = max(steps.count - 1, 0)
        }

        var currentStep = steps[currentStepIndex]
        var currentStepDistance = distanceFrom(userLocation, to: currentStep)

        while currentStepIndex < steps.count - 1 && currentStepDistance < 20 {
            currentStepIndex += 1
            currentStep = steps[currentStepIndex]
            currentStepDistance = distanceFrom(userLocation, to: currentStep)
        }

        updateCurrentInstruction()
        currentStepDistanceText = formattedDistance(currentStepDistance)

        let totalDistance = totalRouteDistance()
        let passedRatio = Double(currentStepIndex) / Double(max(steps.count, 1))
        let remainingDistance = totalDistance * max(0, 1 - passedRatio)

        remainingRouteDistanceText = formattedDistance(remainingDistance)
        remainingRouteTimeText = formattedTravelTime(totalRouteTime() * max(0, 1 - passedRatio))
    }

    private func updateCurrentInstruction() {
        let steps = navigableSteps()
        guard !steps.isEmpty, currentStepIndex < steps.count else { return }

        let instruction = steps[currentStepIndex]
            .instructions
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if isLoopRouteMode {
            if instruction.lowercased().contains("hedefe") ||
                instruction.lowercased().contains("varıyorsunuz") ||
                instruction.isEmpty {

                currentInstruction = "Mavi çizgiyi takip ederek başlangıç noktasına geri dön"
            } else {
                currentInstruction = instruction
            }
        } else {
            currentInstruction = instruction
        }
    }

    private func navigableSteps() -> [MKRoute.Step] {
        routeParts.flatMap { route in
            route.steps.filter {
                !$0.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }

    private func cleanStepTexts(from routes: [MKRoute]) -> [String] {
        routes.flatMap { route in
            route.steps
                .map { $0.instructions.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }

    private func distanceFrom(_ userLocation: CLLocation, to step: MKRoute.Step) -> CLLocationDistance {
        let polyline = step.polyline

        guard polyline.pointCount > 0 else {
            return step.distance
        }

        var coordinates = Array(
            repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            count: polyline.pointCount
        )

        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: polyline.pointCount))

        guard let lastCoordinate = coordinates.last else {
            return step.distance
        }

        let targetLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        return userLocation.distance(from: targetLocation)
    }

    private func updateRemainingRouteInfo() {
        remainingRouteDistanceText = formattedDistance(totalRouteDistance())
        remainingRouteTimeText = formattedTravelTime(totalRouteTime())
    }

    func routeInfoText() -> String? {
        guard !routeParts.isEmpty else { return nil }

        let distanceText = formattedDistance(totalRouteDistance())
        let timeText = formattedTravelTime(totalRouteTime())

        if isLoopRouteMode {
            return "\(distanceText) • Hedef: \(loopTargetDistanceText) • Yaklaşık \(timeText)"
        }

        return "\(distanceText) • Yaklaşık \(timeText)"
    }

    private func totalRouteDistance() -> CLLocationDistance {
        routeParts.reduce(0) { $0 + $1.distance }
    }

    private func totalRouteTime() -> TimeInterval {
        routeParts.reduce(0) { $0 + $1.expectedTravelTime }
    }

    private func formattedDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }

    private func formattedTravelTime(_ time: TimeInterval) -> String {
        let totalMinutes = max(Int(time / 60), 0)

        if totalMinutes < 60 {
            return "\(totalMinutes) dk"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours) sa \(minutes) dk"
        }
    }

    func isFavorite(_ place: PlaceItem) -> Bool {
        favorites.contains(place)
    }

    func toggleFavorite(_ place: PlaceItem) {
        if let index = favorites.firstIndex(of: place) {
            favorites.remove(at: index)
        } else {
            favorites.append(place)
        }

        saveFavorites()
    }

    func removeFavorite(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        saveFavorites()
    }

    func distanceText(for place: PlaceItem) -> String? {
        guard let userLocation = locationService.userLocation else { return nil }

        let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
        let distance = userLocation.distance(from: placeLocation)

        return formattedDistance(distance)
    }

    private func composeAddress(from placemark: MKPlacemark) -> String {
        let parts = [
            placemark.thoroughfare,
            placemark.subThoroughfare,
            placemark.locality,
            placemark.subLocality,
            placemark.administrativeArea
        ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        return parts.isEmpty ? "Adres bilgisi yok" : parts.joined(separator: ", ")
    }

    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: favoritesKey)
        } catch {
            showError("Favoriler kaydedilemedi.")
        }
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey) else { return }

        do {
            favorites = try JSONDecoder().decode([PlaceItem].self, from: data)
        } catch {
            favorites = []
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}
