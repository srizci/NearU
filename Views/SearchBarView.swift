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

    // FIX #8: Boş string kontrolü için yardımcı
    private var isSearchable: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Yer ara...", text: $text)
                    .submitLabel(.search)
                    .onSubmit {
                        if isSearchable { onSearch() }
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
            .clipShape(RoundedRectangle(cornerRadius: 30.0))
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

            // FIX #8: Boşken arama butonu devre dışı
            Button(action: onSearch) {
                Image(systemName: "arrow.right")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(isSearchable ? Color.black.opacity(0.8) : Color.gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 19.0))
            }
            .disabled(!isSearchable)
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
