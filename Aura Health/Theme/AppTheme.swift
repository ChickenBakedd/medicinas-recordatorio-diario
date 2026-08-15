//
//  AppTheme.swift
//  Aura Health
//

import SwiftUI

struct AppTheme {
    var accent: Color = Color(red: 0.28, green: 0.52, blue: 0.84)
    var backgroundTop: Color
    var backgroundBottom: Color
    var doseCard: Color
    var appointmentsCard: Color
    var barFill: Color
    var trackGray: Color
    var chipFill: Color
    var softShadow: Color
    var textPrimary: Color
    var textSecondary: Color
    var textMuted: Color
    var success: Color = Color(red: 0.35, green: 0.72, blue: 0.48)
    
    // Original Light Mode (Claro)
    static let light = AppTheme(
        backgroundTop: Color(red: 0.98, green: 0.96, blue: 0.93),
        backgroundBottom: Color(red: 0.93, green: 0.89, blue: 0.84),
        doseCard: Color(red: 0.96, green: 0.97, blue: 1.0),
        appointmentsCard: Color(red: 1.0, green: 0.96, blue: 0.93),
        barFill: Color(red: 0.99, green: 0.97, blue: 0.94),
        trackGray: Color(red: 0.82, green: 0.79, blue: 0.75),
        chipFill: Color.white.opacity(0.65),
        softShadow: Color.black.opacity(0.07),
        textPrimary: Color(red: 0.22, green: 0.20, blue: 0.18),
        textSecondary: Color(red: 0.42, green: 0.38, blue: 0.34),
        textMuted: Color(red: 0.55, green: 0.50, blue: 0.46)
    )
    
    // Pure Black Mode (Oscuro Puro)
    static let pureBlack = AppTheme(
        backgroundTop: Color(red: 0.07, green: 0.07, blue: 0.07),
        backgroundBottom: Color(red: 0.0, green: 0.0, blue: 0.0),
        doseCard: Color(red: 0.14, green: 0.14, blue: 0.16),
        appointmentsCard: Color(red: 0.16, green: 0.16, blue: 0.18),
        barFill: Color(red: 0.18, green: 0.18, blue: 0.20),
        trackGray: Color(red: 0.30, green: 0.30, blue: 0.32),
        chipFill: Color(white: 0.22),
        softShadow: Color.black.opacity(0.6),
        textPrimary: Color.white,
        textSecondary: Color(white: 0.78),
        textMuted: Color(white: 0.55)
    )
    
    // Blue Dark Mode (Oscuro Azulado)
    static let blueDark = AppTheme(
        backgroundTop: Color(red: 0.07, green: 0.10, blue: 0.20),
        backgroundBottom: Color(red: 0.03, green: 0.05, blue: 0.14),
        doseCard: Color(red: 0.13, green: 0.18, blue: 0.32),
        appointmentsCard: Color(red: 0.15, green: 0.20, blue: 0.36),
        barFill: Color(red: 0.16, green: 0.22, blue: 0.38),
        trackGray: Color(red: 0.22, green: 0.30, blue: 0.50),
        chipFill: Color(red: 0.20, green: 0.28, blue: 0.45),
        softShadow: Color.black.opacity(0.5),
        textPrimary: Color.white,
        textSecondary: Color(red: 0.78, green: 0.84, blue: 0.95),
        textMuted: Color(red: 0.60, green: 0.68, blue: 0.82)
    )
}

struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .light
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

struct OptimalBackground: View {
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        LinearGradient(
            colors: [theme.backgroundTop, theme.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct OptimalCardStyle: ViewModifier {
    @Environment(\.appTheme) private var theme
    var fill: Color
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
                    .shadow(color: theme.softShadow, radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.textPrimary.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func remindMyCard(fill: Color, cornerRadius: CGFloat = 22) -> some View {
        modifier(OptimalCardStyle(fill: fill, cornerRadius: cornerRadius))
    }

    func remindMyScreenBackground() -> some View {
        background(OptimalBackground())
    }
}
struct ThemeModeModifier: ViewModifier {
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @Environment(\.colorScheme) private var systemColorScheme
    
    var preferredColorScheme: ColorScheme? {
        switch appThemeMode {
        case "pureBlack", "blueDark", "graphite": return .dark
        case "light": return .light
        default: return nil
        }
    }
    
    func body(content: Content) -> some View {
        let scheme = preferredColorScheme ?? systemColorScheme
        content
            .preferredColorScheme(preferredColorScheme)
            .environment(\.colorScheme, scheme)
    }
}

extension View {
    func applyThemeMode() -> some View {
        modifier(ThemeModeModifier())
    }
}
