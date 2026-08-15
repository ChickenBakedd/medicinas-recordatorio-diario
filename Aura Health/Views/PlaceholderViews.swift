//
//  PlaceholderViews.swift
//  Aura Health
//

import SwiftUI

// NOTE: MedicationListPlaceholderView and AppointmentsPlaceholderView have been
// replaced by MedicationListView and AppointmentsListView respectively.
// This file is kept for any future placeholder needs.

struct AddItemPlaceholderView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()
                placeholderContent(
                    title: "Añadir",
                    icon: "plus.circle.fill",
                    message: "Próximamente podrás añadir medicación y citas.",
                    theme: theme
                )
            }
            .navigationTitle("Añadir")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cerrar") { dismiss() }
                        .font(.system(.body, design: .rounded).weight(.medium))
                }
            }
        }
    }
}

private func placeholderContent(
    title: String,
    icon: String,
    message: String,
    theme: AppTheme
) -> some View {
    VStack(spacing: 18) {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [theme.accent.opacity(0.18), theme.accent.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 88, height: 88)
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(theme.accent)
        }
        Text(title)
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(theme.textPrimary)
        Text(message)
            .font(.system(.body, design: .rounded))
            .foregroundStyle(theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

import HealthKit

struct EmptyMedicationsView: View {
    var store: MedicationStore
    @Environment(\.appTheme) private var theme
    
    var onAddMedication: () -> Void
    var onImportHealth: () -> Void
    @State private var showingHealthKitAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icono
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "pills.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.accent)
            }
            
            // Textos
            VStack(spacing: 12) {
                Text("Bienvenido a Medicinas")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                
                Text("Añade tu primera medicina para empezar a llevar un registro.")
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, 32)
            }
            
            // Botones
            VStack(spacing: 16) {
                Button(action: onAddMedication) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Añadir Nueva Medicina")
                    }
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.accent)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
        }
    }
}
