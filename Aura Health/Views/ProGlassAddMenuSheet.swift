//
//  ProGlassAddMenuSheet.swift
//  Aura Health
//

import SwiftUI

struct ProGlassAddMenuSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @Bindable var store: MedicationStore

    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }

    @State private var showAddMedication = false
    @State private var showAddAppointment = false
    @State private var showHealthVitals = false

    var body: some View {
        NavigationStack {
            ZStack {
                glassBackground

                VStack(spacing: 24) {
                    Text("¿Qué quieres añadir?")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.primary.opacity(0.8))
                        .padding(.top, 16)

                    // Medicamento
                    ProGlassAddMenuOptionCard(
                        icon: "pills.fill",
                        title: "Medicamento",
                        subtitle: "Añade una pastilla, jarabe u otro medicamento a tu rutina",
                        gradientColors: [Color.blue, Color.purple]
                    ) {
                        showAddMedication = true
                    }

                    // Cita médica
                    ProGlassAddMenuOptionCard(
                        icon: "calendar.badge.plus",
                        title: "Cita Médica",
                        subtitle: "Agenda una nueva cita con tu médico o especialista",
                        gradientColors: [Color.orange, Color.pink]
                    ) {
                        showAddAppointment = true
                    }
                    
                    // Control de Salud
                    ProGlassAddMenuOptionCard(
                        icon: "heart.fill",
                        title: "Medición Vital",
                        subtitle: "Registra tu peso, presión arterial o glucosa",
                        gradientColors: [Color.red, Color.pink]
                    ) {
                        showHealthVitals = true
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.gray.opacity(0.5))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .applyThemeMode()
        }
        .sheet(isPresented: $showAddMedication) {
            ProGlassAddMedicationView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
        .sheet(isPresented: $showAddAppointment) {
            ProGlassAddAppointmentView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
        .sheet(isPresented: $showHealthVitals) {
            ProGlassHealthVitalsView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
    }
    
    private var glassBackground: some View {
        ZStack {
            if isGraphite {
                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            } else {
                (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -150, y: -200)
                
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: 150, y: 150)
                    
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: -50, y: 350)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Option Card

struct ProGlassAddMenuOptionCard: View {
    @Environment(\.appTheme) private var theme
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @State private var isPressed = false

    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)

    private var circleColors: [Color] {
        if isGraphite { return [gold.opacity(0.15), gold.opacity(0.1)] }
        if isDark { return [Color.green.opacity(0.2), Color.mint.opacity(0.15)] }
        return gradientColors.map { $0.opacity(0.15) }
    }

    private var iconForeground: AnyShapeStyle {
        if isGraphite { return AnyShapeStyle(gold) }
        if isDark { return AnyShapeStyle(Color.green) }
        return AnyShapeStyle(LinearGradient(colors: gradientColors.map { $0.opacity(0.8) }, startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: circleColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(iconForeground)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(isGraphite ? Color.white.opacity(0.9) : Color.primary.opacity(0.8))
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(isGraphite ? Color.white.opacity(0.4) : Color.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.gray.opacity(0.4))
            }
            .padding(20)
            .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : (colorScheme == .dark ? Color.black : Color.white).opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isGraphite ? (isPressed ? 0.3 : 0.4) : (isPressed ? 0.02 : 0.08)), radius: 15, y: isPressed ? 2 : 6)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
