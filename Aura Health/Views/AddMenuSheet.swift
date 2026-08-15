//
//  AddMenuSheet.swift
//  Aura Health
//

import SwiftUI

struct AddMenuSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: MedicationStore

    @State private var showAddMedication = false
    @State private var showAddAppointment = false
    @State private var showHealthVitals = false

    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()

                VStack(spacing: 20) {
                    Text("¿Qué quieres añadir?")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.top, 8)

                    // Medicamento
                    AddMenuOptionCard(
                        icon: "pills.fill",
                        title: "Medicamento",
                        subtitle: "Añade una pastilla, jarabe u otro medicamento a tu rutina",
                        tint: theme.accent
                    ) {
                        showAddMedication = true
                    }

                    // Cita médica
                    AddMenuOptionCard(
                        icon: "calendar.badge.plus",
                        title: "Cita Médica",
                        subtitle: "Agenda una nueva cita con tu médico o especialista",
                        tint: Color(red: 0.75, green: 0.45, blue: 0.32)
                    ) {
                        showAddAppointment = true
                    }
                    
                    // Control de Salud
                    AddMenuOptionCard(
                        icon: "heart.fill",
                        title: "Medición Vital",
                        subtitle: "Registra tu peso, presión arterial o glucosa",
                        tint: .red
                    ) {
                        showHealthVitals = true
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(theme.accent)
                }
            }
            .applyThemeMode()
        }
        .sheet(isPresented: $showAddMedication) {
            AddMedicationView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
        .sheet(isPresented: $showAddAppointment) {
            AddAppointmentView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
        .sheet(isPresented: $showHealthVitals) {
            HealthVitalsView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
    }
}

// MARK: - Option Card

struct AddMenuOptionCard: View {
    @Environment(\.appTheme) private var theme
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(
                            colors: [tint.opacity(0.2), tint.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(tint.opacity(0.6))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.barFill)
                    .shadow(color: theme.softShadow, radius: 10, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(tint.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    AddMenuSheet(store: MedicationStore())
}
