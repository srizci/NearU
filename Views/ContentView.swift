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
            ChatView(selectedTab: $selectedTab)
                .environmentObject(viewModel)
                .tabItem {
                    Label("Asistan", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(0)

            MapScreen(selectedTab: $selectedTab)
                .environmentObject(viewModel)
                .tabItem {
                    Label("Harita", systemImage: "map.fill")
                }
                .tag(1)

            FavoritesView(selectedTab: $selectedTab)
                .environmentObject(viewModel)
                .tabItem {
                    Label("Favoriler", systemImage: "heart.fill")
                }
                .tag(2)

            LoopRouteView(selectedTab: $selectedTab)
                .environmentObject(viewModel)
                .tabItem {
                    Label("Koşu", systemImage: "figure.run")
                }
                .tag(3)
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
