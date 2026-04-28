//
//  AppStyle.swift
//  NearU
//
//  Created by Şura İZCİ on 28.04.2026.
//

import SwiftUI

extension Color {
    static let appPrimary = Color.blue
    static let appAccent = Color.green
    static let cardBg = Color(.systemBackground)
    static let softBg = Color(.secondarySystemBackground)
}

struct MainButtonStyle: ButtonStyle {
    var color: Color = .appPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
