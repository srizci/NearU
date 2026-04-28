//
//  ContentView.swift
//  NearU
//
//  Created by Şura İZCİ on 31.03.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MapScreen(selectedTab: $selectedTab)
                .environmentObject(viewModel)
                .tabItem {
                    Label("Harita", systemImage: "map.fill")
                }
                .tag(0)

            FavoritesView(selectedTab: $selectedTab)
                .environmentObject(viewModel)
                .tabItem {
                    Label("Favoriler", systemImage: "heart.fill")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
