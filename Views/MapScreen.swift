//
//  MapScreen.swift
//  NearU
//

import SwiftUI
import MapKit

struct MapScreen: View {
    @EnvironmentObject var viewModel: MapViewModel
    @Binding var selectedTab: Int

    var body: some View {
        ZStack {
            MapViewRepresentable(
                region: $viewModel.region,
                places: viewModel.places,
                selectedPlace: viewModel.selectedPlace,
                routeParts: viewModel.routeParts,
                alternativeRoutes: viewModel.alternativeRoutes,
                selectedRouteIndex: viewModel.selectedRouteIndex,
                onSelectPlace: { place in
                    viewModel.selectPlace(place)
                },
                onTapCoordinate: { coordinate in
                    viewModel.selectPlaceFromMapTap(at: coordinate)
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                SearchBarView(
                    text: $viewModel.searchText,
                    onSearch: {
                        viewModel.searchPlaces()
                    },
                    onClear: {
                        viewModel.places = []
                        viewModel.selectedPlace = nil
                        viewModel.clearRoute()
                    }
                )
                .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(NearbyCategory.allCases) { category in
                            Button {
                                viewModel.searchNearby(category: category)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: category.iconName)
                                    Text(category.rawValue)
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(viewModel.activeCategory == category ? .white : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.activeCategory == category
                                    ? Color.blue
                                    : Color(.systemBackground)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                if viewModel.isLoading {
                    ProgressView("Yükleniyor...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if !viewModel.places.isEmpty &&
                    viewModel.routeParts.isEmpty &&
                    viewModel.selectedPlace == nil &&
                    !viewModel.isShowingRoutePreview &&
                    !viewModel.isNavigating {

                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(viewModel.places) { place in
                                Button {
                                    viewModel.selectPlace(place)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(place.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        if let address = place.address {
                                            Text(address)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .lineLimit(2)
                                        }

                                        HStack(spacing: 10) {
                                            // FIX #7: Ham kategori yerine okunabilir kategori
                                            if let category = place.readableCategory {
                                                Text(category)
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }

                                            if let distance = viewModel.distanceText(for: place) {
                                                Text(distance)
                                                    .font(.caption)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 220)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal)
                }

                HStack {
                    Spacer()

                    VStack(spacing: 12) {
                        Button {
                            viewModel.zoomIn()
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(width: 46, height: 46)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 4)
                        }

                        Button {
                            viewModel.zoomOut()
                        } label: {
                            Image(systemName: "minus")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(width: 46, height: 46)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 4)
                        }

                        Button {
                            viewModel.centerMapOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 52, height: 52)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 4)
                        }
                    }
                    .padding(.trailing)
                }

                // FIX #3: PlaceDetailView sadece rota yokken gösteriliyor
                // "Rotayı Temizle" butonu da sadece rota varsa gösterilecek (PlaceDetailView'da düzeltildi)
                if let selectedPlace = viewModel.selectedPlace,
                   !viewModel.isShowingRoutePreview,
                   !viewModel.isNavigating {
                    PlaceDetailView(
                        place: selectedPlace,
                        isFavorite: viewModel.isFavorite(selectedPlace),
                        distanceText: viewModel.distanceText(for: selectedPlace),
                        routeInfoText: viewModel.routeInfoText(),
                        hasRoute: !viewModel.routeParts.isEmpty,
                        selectedTransportType: $viewModel.selectedTransportType,
                        onClose: {
                            viewModel.selectedPlace = nil
                        },
                        onToggleFavorite: {
                            viewModel.toggleFavorite(selectedPlace)
                        },
                        onCreateRoute: {
                            viewModel.calculateRoute()
                        },
                        onClearRoute: {
                            viewModel.clearRoute()
                        }
                    )
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if viewModel.isShowingRoutePreview, !viewModel.routeParts.isEmpty {
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(viewModel.isLoopRouteMode ? "Koşu/Yürüyüş Rota Önizleme" : "Rota Önizleme")
                                    .font(.headline)

                                if !viewModel.previewDestinationName.isEmpty {
                                    Text(viewModel.previewDestinationName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                viewModel.clearRoute()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Circle())
                            }
                        }

                        // Alternatif rota kartları (döngüsel rotada gösterme)
                        if !viewModel.isLoopRouteMode && viewModel.alternativeRoutes.count > 1 {
                            let routeLabels = ["En Kısa", "Alternatif", "3. Seçenek"]
                            let routeColors: [Color] = [.blue, .orange, .purple]

                            VStack(spacing: 8) {
                                ForEach(Array(viewModel.alternativeRoutes.enumerated()), id: \.offset) { idx, altRoute in
                                    let isSelected = viewModel.selectedRouteIndex == idx
                                    let distKm = altRoute.distance >= 1000
                                        ? String(format: "%.1f km", altRoute.distance / 1000)
                                        : "\(Int(altRoute.distance)) m"
                                    let mins = max(Int(altRoute.expectedTravelTime / 60), 1)
                                    let timeStr = mins < 60 ? "\(mins) dk" : "\(mins/60) sa \(mins%60) dk"

                                    Button {
                                        viewModel.selectAlternativeRoute(at: idx)
                                    } label: {
                                        HStack(spacing: 12) {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(routeColors[idx % routeColors.count])
                                                .frame(width: 4, height: 36)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(routeLabels[idx % routeLabels.count])
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(isSelected ? .primary : .secondary)
                                                Text("\(distKm)  •  \(timeStr)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.title3)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            isSelected
                                            ? routeColors[idx % routeColors.count].opacity(0.1)
                                            : Color(.tertiarySystemBackground)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    isSelected ? routeColors[idx % routeColors.count] : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                    }
                                }
                            }
                        } else if let info = viewModel.routeInfoText() {
                            // Tek rota veya döngüsel rota — eski bilgi satırı
                            Text(info)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !viewModel.routeStepTexts.isEmpty {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(Array(viewModel.routeStepTexts.enumerated()), id: \.offset) { index, step in
                                        HStack(alignment: .top, spacing: 10) {
                                            Text("\(index + 1).")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.blue)

                                            Text(step)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 140)
                        }

                        Button {
                            viewModel.startNavigation()
                        } label: {
                            Text("Rotayı Başlat")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }

                if viewModel.isNavigating, !viewModel.routeParts.isEmpty {
                    VStack(spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(viewModel.hasArrived ? "Navigasyon Tamamlandı" : "Aktif Navigasyon")
                                    .font(.headline)

                                Text(
                                    viewModel.currentInstruction.isEmpty
                                    ? "Yön bilgisi hazırlanıyor..."
                                    : viewModel.currentInstruction
                                )
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                                if viewModel.isLoopRouteMode {
                                    Text("Seçilen koşu/yürüyüş rotasını tamamlamak için haritadaki mavi çizgiyi takip et.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                if !viewModel.currentStepDistanceText.isEmpty && !viewModel.hasArrived {
                                    Text("\(viewModel.currentStepDistanceText) sonra")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }

                            Spacer()

                            Button {
                                viewModel.stopNavigation()
                                viewModel.clearRoute()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Circle())
                            }
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kalan Mesafe")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(viewModel.remainingRouteDistanceText.isEmpty ? "-" : viewModel.remainingRouteDistanceText)
                                    .font(.headline)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Kalan Süre")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(viewModel.remainingRouteTimeText.isEmpty ? "-" : viewModel.remainingRouteTimeText)
                                    .font(.headline)
                            }
                        }

                        if viewModel.hasArrived {
                            Button {
                                viewModel.clearRoute()
                            } label: {
                                Text("Navigasyonu Bitir")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
            }
        }
        // FIX #5: onDisappear'da konum güncellemesi durduruluyor (pil tasarrufu)
        .onAppear {
            viewModel.startLocationUpdates()
        }
        .onDisappear {
            if !viewModel.isNavigating {
                viewModel.stopLocationUpdates()
            }
        }
        .alert("Uyarı", isPresented: $viewModel.showErrorAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedPlace)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isShowingRoutePreview)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isNavigating)
    }
}

#Preview {
    MapScreen(selectedTab: .constant(0))
        .environmentObject(MapViewModel())
}
