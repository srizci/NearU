//
//  PlaceDetailView.swift
//  NearU
//
//  Created by Şura İZCİ on 31.03.2026.
//

import SwiftUI
import MapKit

struct PlaceDetailView: View {
    let place: PlaceItem
    let isFavorite: Bool
    let distanceText: String?
    let routeInfoText: String?

    @Binding var selectedTransportType: TransportType

    var onClose: () -> Void
    var onToggleFavorite: () -> Void
    var onCreateRoute: () -> Void
    var onClearRoute: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(place.name)
                        .font(.title3.bold())

                    Text(place.address ?? "Adres bilgisi yok")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        if let category = place.category, !category.isEmpty {
                            Label(category, systemImage: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        if let distanceText = distanceText {
                            Label(distanceText, systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    if let routeInfoText = routeInfoText {
                        Text(routeInfoText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Ulaşım Türü")
                    .font(.subheadline.bold())

                Picker("Ulaşım Türü", selection: $selectedTransportType) {
                    ForEach(TransportType.allCases) { type in
                        Label(type.rawValue, systemImage: type.iconName)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 12) {
                Button(action: onToggleFavorite) {
                    Label(
                        isFavorite ? "Favoriden Çıkar" : "Favoriye Ekle",
                        systemImage: isFavorite ? "heart.fill" : "heart"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isFavorite ? Color.pink.opacity(0.15) : Color.orange.opacity(0.15))
                    .foregroundColor(isFavorite ? .pink : .orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onCreateRoute) {
                    Label("Rota Oluştur", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Button(action: onClearRoute) {
                Text("Rotayı Temizle")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview {
    PlaceDetailView(
        place: PlaceItem(
            name: "Meram Tıp Fakültesi",
            coordinate: CLLocationCoordinate2D(latitude: 37.86, longitude: 32.47),
            address: "Konya, Türkiye",
            category: "Hospital"
        ),
        isFavorite: false,
        distanceText: "1.4 km",
        routeInfoText: "2.1 km • Yaklaşık 6 dk",
        selectedTransportType: .constant(.automobile),
        onClose: {},
        onToggleFavorite: {},
        onCreateRoute: {},
        onClearRoute: {}
    )
}
