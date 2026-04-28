//
//  LoopRouteView.swift
//  NearU
//
//  Created by Şura İZCİ on 28.04.2026.
//

import SwiftUI

struct LoopRouteView: View {
    @EnvironmentObject var viewModel: MapViewModel
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Koşu / Yürüyüş Rotası")
                        .font(.title2.bold())

                    Text("Başlangıç ve bitiş noktası aynı olacak şekilde hedef mesafene uygun rota oluştur.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Mesafe", selection: $viewModel.selectedLoopDistance) {
                    ForEach(LoopRouteDistance.allCases) { distance in
                        Text(distance.title).tag(distance)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    viewModel.calculateLoopRoute()
                    selectedTab = 0
                } label: {
                    HStack {
                        Image(systemName: "figure.run")
                        Text("Rota Oluştur")
                    }
                }
                .buttonStyle(MainButtonStyle(color: .appAccent))

                Spacer()
            }
            .padding()
            .navigationTitle("Koşu")
        }
    }
}
