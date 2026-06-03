//
//  MapViewRepresentable.swift
//  NearU
//

import SwiftUI
import MapKit

final class PlaceAnnotation: NSObject, MKAnnotation {
    let place: PlaceItem

    var coordinate: CLLocationCoordinate2D { place.coordinate }
    var title: String? { place.name }
    var subtitle: String? { place.address }

    init(place: PlaceItem) {
        self.place = place
        super.init()
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    let places: [PlaceItem]
    let selectedPlace: PlaceItem?
    let routeParts: [MKRoute]
    let alternativeRoutes: [MKRoute]
    let selectedRouteIndex: Int
    let onSelectPlace: (PlaceItem) -> Void
    let onTapCoordinate: (CLLocationCoordinate2D) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.pointOfInterestFilter = .includingAll
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.setRegion(region, animated: false)

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMapTap(_:))
        )
        tapGesture.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self

        let oldAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(oldAnnotations)

        var allPlaces = places
        if let selectedPlace, !allPlaces.contains(selectedPlace) {
            allPlaces.append(selectedPlace)
        }

        let annotations = allPlaces.map { PlaceAnnotation(place: $0) }
        mapView.addAnnotations(annotations)

        mapView.removeOverlays(mapView.overlays)

        // Önizleme modunda: tüm alternatif rotaları çiz (seçili en üste gelsin)
        let routesToDraw: [MKRoute]
        if !alternativeRoutes.isEmpty {
            // Seçili olmayan rotalar önce, seçili rota en son (en üstte)
            let unselected = alternativeRoutes.enumerated()
                .filter { $0.offset != selectedRouteIndex }
                .map { $0.element }
            let selected = selectedRouteIndex < alternativeRoutes.count
                ? [alternativeRoutes[selectedRouteIndex]] : []
            routesToDraw = unselected + selected
        } else {
            routesToDraw = routeParts
        }

        if !routesToDraw.isEmpty {
            for route in routesToDraw {
                mapView.addOverlay(route.polyline)
            }

            let allRoutes = alternativeRoutes.isEmpty ? routeParts : alternativeRoutes
            var mapRect = allRoutes[0].polyline.boundingMapRect
            for route in allRoutes.dropFirst() {
                mapRect = mapRect.union(route.polyline.boundingMapRect)
            }

            let insets = UIEdgeInsets(top: 120, left: 50, bottom: 260, right: 50)
            mapView.setVisibleMapRect(mapRect, edgePadding: insets, animated: true)
        } else {
            let currentCenter = mapView.region.center
            let currentSpan = mapView.region.span

            let centerChanged =
                abs(currentCenter.latitude - region.center.latitude) > 0.0005 ||
                abs(currentCenter.longitude - region.center.longitude) > 0.0005

            let spanChanged =
                abs(currentSpan.latitudeDelta - region.span.latitudeDelta) > 0.0005 ||
                abs(currentSpan.longitudeDelta - region.span.longitudeDelta) > 0.0005

            if centerChanged || spanChanged {
                mapView.setRegion(region, animated: true)
            }
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        // FIX #10: Region geri yazımını debounce etmek için timer
        private var regionChangeTimer: Timer?

        init(parent: MapViewRepresentable) {
            self.parent = parent
        }

        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }

            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            parent.onTapCoordinate(coordinate)
        }

        // FIX #10: Her kaydırmada değil, 0.15 sn debounce ile ViewModel güncelleniyor
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            regionChangeTimer?.invalidate()
            regionChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
                self?.parent.region = mapView.region
            }
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? PlaceAnnotation else { return }
            parent.onSelectPlace(annotation.place)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }

            let identifier = "PlaceAnnotationView"
            var annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier
            ) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(
                    annotation: annotation,
                    reuseIdentifier: identifier
                )
                annotationView?.canShowCallout = true
            }

            annotationView?.annotation = annotation
            annotationView?.markerTintColor = .systemRed
            annotationView?.glyphImage = UIImage(systemName: "mappin.circle.fill")

            return annotationView
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.lineJoin = .round
                renderer.lineCap = .round

                // Alternatif rotalar varken seçili olanı mavi/kalın, diğerlerini gri/ince göster
                let routes = parent.alternativeRoutes.isEmpty ? parent.routeParts : parent.alternativeRoutes
                if let idx = routes.firstIndex(where: { $0.polyline === polyline }) {
                    if idx == parent.selectedRouteIndex {
                        renderer.strokeColor = .systemBlue
                        renderer.lineWidth = 7
                        renderer.alpha = 1.0
                    } else {
                        renderer.strokeColor = .systemGray
                        renderer.lineWidth = 4
                        renderer.alpha = 0.55
                    }
                } else {
                    renderer.strokeColor = .systemBlue
                    renderer.lineWidth = 6
                    renderer.alpha = 1.0
                }

                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
