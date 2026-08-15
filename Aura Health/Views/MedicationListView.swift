//
//  MedicationListView.swift
//  Aura Health
//

import SwiftUI

struct MedicationListView: View {
    @Environment(\.appTheme) private var theme
    @Bindable var store: MedicationStore
    @State private var editingDose: MedicationDose? = nil
    @State private var showAddMedication = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mi Medicación")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.textPrimary)
                        Text("\(store.doses.count) medicamento\(store.doses.count == 1 ? "" : "s") configurado\(store.doses.count == 1 ? "" : "s")")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(theme.textMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 12)

                if store.doses.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.dosesSortedByTime) { dose in
                            MedicationRowCard(dose: dose) {
                                editingDose = dose
                            } onDelete: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    store.deleteDose(id: dose.id)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .sheet(item: $editingDose) { dose in
            AddMedicationView(store: store, existingDose: dose)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [theme.accent.opacity(0.15), theme.accent.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                Image(systemName: "pills.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(theme.accent)
            }
            Text("Sin medicamentos")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(theme.textPrimary)
            Text("Pulsa el botón + para añadir tu primer medicamento")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Row Card

struct MedicationRowCard: View {
    @Environment(\.appTheme) private var theme
    let dose: MedicationDose
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [theme.accent.opacity(0.18), theme.accent.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: dose.form.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(theme.accent)
                        .rotationEffect(.degrees(dose.form == .pill ? -45 : 0))
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(dose.medicationName)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                    HStack(spacing: 6) {
                        if let mg = dose.milligrams {
                            Text("\(mg) mg")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(theme.accent.opacity(0.1)))
                        }
                        Text(dose.amount.rawValue)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                Spacer()

                // Time + chevron
                VStack(alignment: .trailing, spacing: 4) {
                    Text(dose.timeLabel)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.accent)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(theme.textMuted)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.barFill)
                    .shadow(color: theme.softShadow, radius: 8, y: 3)
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Eliminar", systemImage: "trash.fill")
            }
        }
    }
}

#Preview {
    MedicationListView(store: MedicationStore())
}
