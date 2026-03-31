//
//  MapViewModel.swift
//  NearU
//
//  Created by Şura İZCİ on 31.03.2026.
//
import SwiftUI
import MapKit
import CoreLocation
import Combine

final class MapViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedPlace: PlaceItem? = nil
    @Published var places: [PlaceItem] = []

    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.8746, longitude: 32.4932),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    let locationService = LocationService()

    init() {
        locationService.requestPermission()
    }

    func startLocationUpdates() {
        locationService.startUpdatingLocation()
    }

    func centerMapOnUser() {
        guard let coordinate = locationService.userLocation?.coordinate else { return }

        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }

    func searchPlaces() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region

        let search = MKLocalSearch(request: request)

        search.start { [weak self] response, error in
            guard let self = self, let response = response else {
                print("Arama hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                return
            }

            self.places = response.mapItems.map { item in
                PlaceItem(
                    name: item.name ?? "Bilinmeyen Yer",
                    coordinate: item.placemark.coordinate,
                    address: item.placemark.title,
                    category: item.pointOfInterestCategory?.rawValue
                )
            }

            if let firstPlace = self.places.first {
                self.region = MKCoordinateRegion(
                    center: firstPlace.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
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
}
