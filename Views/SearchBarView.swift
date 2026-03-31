//
//  SearchBarView.swift
//  NearU
//
//  Created by Şura İZCİ on 31.03.2026.
//
import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var onSearch: () -> Void

    var body: some View {
        HStack {
            TextField("Yer ara...", text: $text)
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(10)

            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    SearchBarView(text: .constant("Konya"), onSearch: {})
}
