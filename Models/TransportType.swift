//
//  TransportType.swift
//  NearU
//
//  Created by Şura İZCİ on 31.03.2026.
//

import Foundation
import MapKit

enum TransportType: String, CaseIterable, Identifiable {
    case automobile = "Araba"
    case walking = "Yürüyüş"
    case transit = "Toplu Taşıma"

    var id: String { rawValue }

    var mkType: MKDirectionsTransportType {
        switch self {
        case .automobile:
            return .automobile
        case .walking:
            return .walking
        case .transit:
            return .transit
        }
    }

    var iconName: String {
        switch self {
        case .automobile:
            return "car.fill"
        case .walking:
            return "figure.walk"
        case .transit:
            return "tram.fill"
        }
    }
}
