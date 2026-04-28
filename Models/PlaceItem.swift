//
//  PlaceItem.swift
//  NearU
//
//  Created by Şura İZCİ on 31.03.2026.
//

import Foundation
import MapKit

struct PlaceItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let category: String?

    init(
        name: String,
        coordinate: CLLocationCoordinate2D,
        address: String? = nil,
        category: String? = nil
    ) {
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
        self.category = category

        let safeName = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")

        self.id = "\(safeName)_\(latitude)_\(longitude)"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
