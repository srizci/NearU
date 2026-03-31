//
//  MapScreen.swift
//  NearU
//
//  Created by Şura İZCİ on 31.03.2026.
//

import SwiftUI
import MapKit

struct MapScreen: View {
    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            Map(
                coordinateRegion: $viewModel.region,
                showsUserLocation: true,
                annotationItems: viewModel.places
            ) { place in
                MapMarker(coordinate: place.coordinate, tint: .red)
            }
            .ignoresSafeArea()

            VStack {
                SearchBarView(text: $viewModel.searchText) {
                    viewModel.searchPlaces()
                }
                .padding(.top, 10)

                Spacer()

                if !viewModel.places.isEmpty {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(viewModel.places) { place in
                                Button(action: {
                                    viewModel.selectPlace(place)
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(place.name)
                                            .font(.headline)
                                            .foregroundColor(.black)

                                        if let address = place.address {
                                            Text(address)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(radius: 2)
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 250)
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }

                Button(action: {
                    viewModel.centerMapOnUser()
                }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .padding()
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            viewModel.startLocationUpdates()
        }
        .onReceive(viewModel.locationService.$userLocation) { location in
            if location != nil {
                viewModel.centerMapOnUser()
            }
        }
    }
}

#Preview {
    MapScreen()
}
