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
    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Yer ara...", text: $text)
                    .submitLabel(.search)
                    .onSubmit {
                        onSearch()
                    }

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        onClear()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

            Button(action: onSearch) {
                Image(systemName: "arrow.right")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    SearchBarView(
        text: .constant("Konya"),
        onSearch: {},
        onClear: {}
    )
}
