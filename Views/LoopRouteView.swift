//
//  LoopRouteView.swift
//  NearU
//
//  Created by Şura İZCİ on 28.04.2026.
//

import SwiftUI
internal import CoreLocation

struct LoopRouteView: View {
    @EnvironmentObject var viewModel: MapViewModel
    @Binding var selectedTab: Int

    // FIX #9: Konum izni kontrolü için yardımcı
    private var hasLocationPermission: Bool {
        guard let status = viewModel.locationService.authorizationStatus else { return false }
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

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

                // FIX #9: Konum izni yoksa uyarı göster
                if !hasLocationPermission {
                    HStack(spacing: 10) {
                        Image(systemName: "location.slash.fill")
                            .foregroundColor(.orange)
                        Text("Rota oluşturmak için konum iznine ihtiyaç var. Lütfen Ayarlar'dan konum iznini etkinleştir.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

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
                // FIX #9: Konum izni yokken buton pasif
                .disabled(!hasLocationPermission)
                .opacity(hasLocationPermission ? 1.0 : 0.5)

                Spacer()
            }
            .padding()
            .navigationTitle("Koşu")
        }
    }
}
