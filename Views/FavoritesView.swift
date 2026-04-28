//
//  FavoritesView.swift
//  NearU
//
//  Created by Şura İZCİ on 31.03.2026.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var viewModel: MapViewModel
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 42))
                            .foregroundColor(.gray)

                        Text("Henüz favori yer eklenmedi")
                            .font(.headline)

                        Text("Haritadaki bir yeri seçip favorilere eklediğinde burada görünecek.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.favorites) { place in
                            Button {
                                viewModel.selectPlace(place)
                                selectedTab = 0
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(place.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    if let address = place.address {
                                        Text(address)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }

                                    HStack(spacing: 10) {
                                        if let category = place.category {
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
                                .padding(.vertical, 6)
                            }
                        }
                        .onDelete(perform: viewModel.removeFavorite)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Favoriler")
        }
    }
}

#Preview {
    FavoritesView(selectedTab: .constant(1))
        .environmentObject(MapViewModel())
}
