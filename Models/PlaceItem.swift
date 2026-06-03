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

        // FIX #1: UUID kullanarak ID çakışması önlendi
        self.id = UUID().uuidString
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // FIX #7: Ham MKPOICategory string'ini okunabilir hale getiren yardımcı
    var readableCategory: String? {
        guard let category else { return nil }
        // "MKPOICategory_Restaurant" → "Restaurant"
        if let range = category.range(of: "_") {
            let readable = String(category[range.upperBound...])
            return readable.isEmpty ? nil : readable
        }
        return category
    }
}
