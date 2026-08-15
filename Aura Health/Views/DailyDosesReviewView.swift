//
//  DailyDosesReviewView.swift
//  Aura Health
//

import SwiftUI

struct DailyDosesReviewView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: MedicationStore

    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Toca una toma para corregir si te has equivocado al marcarla.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                            .padding(.horizontal, 4)

                        ForEach(store.dosesSortedByTime) { dose in
                            doseRow(dose)
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Tomas de hoy")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.medium))
                }
            }
        }
    }

    private func doseRow(_ dose: MedicationDose) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                store.setDoseTaken(id: dose.id, taken: !dose.isTaken)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            dose.isTaken
                                ? theme.success.opacity(0.18)
                                : theme.trackGray.opacity(0.35)
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: dose.isTaken ? "checkmark" : "capsule.fill")
                        .font(.system(size: dose.isTaken ? 16 : 18, weight: .semibold))
                        .foregroundStyle(dose.isTaken ? theme.success : theme.textMuted)
                        .rotationEffect(.degrees(dose.isTaken ? 0 : -45))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(dose.medicationName)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.textPrimary)

                        Spacer()

                        Text(dose.timeLabel)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(dose.isTaken ? theme.success : theme.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        dose.isTaken
                                            ? theme.success.opacity(0.15)
                                            : theme.chipFill
                                    )
                            )
                    }

                    HStack(spacing: 6) {
                        if let mg = dose.milligrams {
                            Text("\(mg) mg")
                        }
                        Text("·")
                        Text(dose.amount.displayText(for: dose.form))
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(theme.textSecondary)

                    Text(dose.isTaken ? "Tomada — toca para desmarcar" : "Pendiente — toca para marcar")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(dose.isTaken ? theme.success : theme.textMuted)
                }
            }
            .padding(16)
            .remindMyCard(
                fill: dose.isTaken ? theme.doseCard : theme.barFill,
                cornerRadius: 16
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DailyDosesReviewView(store: MedicationStore())
}
