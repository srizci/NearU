//
//  PlaceItem.swift
//  NearU
//
//  Created by Şura İZCİ on 31.03.2026.
//
import Foundation
import MapKit

struct PlaceItem: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let category: String?
}
