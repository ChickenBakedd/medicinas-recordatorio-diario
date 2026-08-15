//
//  ProGlassMedicationListView.swift
//  Aura Health
//

import SwiftUI

struct ProGlassMedicationListView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @Bindable var store: MedicationStore
    @State private var editingDose: MedicationDose? = nil
    @State private var showAddMedication = false

    private var isGraphite: Bool { appThemeMode == "graphite" }

    var body: some View {
        ZStack {
            // Re-use the animated background logic from HomeView or just transparent if MainTabView already has it
            // MainTabView provides the background, so we just use clear here, or if we need the animated circles we could extract them.
            // Wait, MainTabView currently has `OptimalBackground()`. In ProGlassHomeView we overlaid our own `glassBackground`.
            // Let's add the glass background here as well if we want the lists to look the same.
            
            glassBackground

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mi Medicación")
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(isGraphite ? Color.white.opacity(0.9) : Color.primary.opacity(0.8))
                        Text("\(store.doses.count) medicamento\(store.doses.count == 1 ? "" : "s") configurado\(store.doses.count == 1 ? "" : "s")")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(isGraphite ? Color.white.opacity(0.35) : Color.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 12)

                if store.doses.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(store.dosesSortedByTime) { dose in
                                ProGlassMedicationRowCard(dose: dose) {
                                    editingDose = dose
                                } onDelete: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        store.deleteDose(id: dose.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .sheet(item: $editingDose) { dose in
            ProGlassAddMedicationView(store: store, existingDose: dose)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
    }
    
    private var glassBackground: some View {
        ZStack {
            if isGraphite {
                Color.clear.ignoresSafeArea()
            } else {
                (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 350, height: 350)
                    .blur(radius: 60)
                    .offset(x: -100, y: -200)
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 150, y: 300)
            }
        }
        .ignoresSafeArea()
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                
                Image(systemName: "pills.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            Text("Sin medicamentos")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.primary.opacity(0.8))
            Text("Pulsa el botón + para añadir tu primer medicamento")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Row Card

struct ProGlassMedicationRowCard: View {
    @Environment(\.appTheme) private var theme
    let dose: MedicationDose
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"

    private var isDark: Bool { appThemeMode == "pureBlack" }
    private var isGraphite: Bool { appThemeMode == "graphite" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)

    @State private var showDeleteConfirm = false
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                // Ícono
                ZStack {
                    Circle()
                        .fill(
                            isGraphite
                            ? LinearGradient(colors: [gold.opacity(0.2), gold.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : isDark
                            ? LinearGradient(colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                    Image(systemName: dose.form == .pill ? "capsule.fill" : "cross.vial.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(isGraphite ? gold : isDark ? Color.green : Color.blue)
                        .rotationEffect(.degrees(dose.form == .pill ? -45 : 0))
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(dose.medicationName)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(isGraphite ? Color.white.opacity(0.9) : Color.primary.opacity(0.8))

                    HStack(spacing: 6) {
                        if let mg = dose.milligrams {
                            Text("\(mg) mg")
                        }
                        Text("•")
                        Text(dose.amount.rawValue)
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(isGraphite ? Color.white.opacity(0.4) : Color.gray)
                }

                Spacer()

                // Hora
                VStack(alignment: .trailing, spacing: 6) {
                    Text(dose.timeLabel)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(isGraphite ? gold : isDark ? Color.green : Color.primary.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            isGraphite ? gold.opacity(0.12)
                            : isDark ? Color.green.opacity(0.15)
                            : (colorScheme == .dark ? Color.black : Color.white).opacity(0.5)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isGraphite ? gold.opacity(0.2)
                        : isDark ? Color.green.opacity(0.2)
                        : Color.white.opacity(0.5),
                        lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isGraphite ? 0.4 : 0.05), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "¿Eliminar \(dose.medicationName)?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                onDelete()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borrará esta medicación y su historial. Esta acción no se puede deshacer.")
        }
    }
}
