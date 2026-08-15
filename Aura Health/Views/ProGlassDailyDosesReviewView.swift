//
//  ProGlassDailyDosesReviewView.swift
//  Aura Health
//

import SwiftUI

struct ProGlassDailyDosesReviewView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @Bindable var store: MedicationStore

    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)

    private var tint: Color {
        isGraphite ? gold : isDark ? Color.green : Color.blue
    }

    var body: some View {
        NavigationStack {
            ZStack {
                glassBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Toca una toma para corregir si te has equivocado al marcarla.")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(Color.gray)
                            .padding(.horizontal, 4)

                        VStack(spacing: 16) {
                            ForEach(store.dosesSortedByTime) { dose in
                                doseRow(dose)
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Tomas de hoy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.gray.opacity(0.6))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
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
                    .frame(width: 350, height: 350)
                    .blur(radius: 60)
                    .offset(x: -150, y: -200)
                
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 150, y: 300)
            }
        }
        .ignoresSafeArea()
    }

    private func doseRow(_ dose: MedicationDose) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                store.setDoseTaken(id: dose.id, taken: !dose.isTaken)
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            dose.isTaken
                                ? tint.opacity(0.15)
                                : Color.gray.opacity(0.1)
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: dose.isTaken ? "checkmark" : "capsule.fill")
                        .font(.system(size: dose.isTaken ? 20 : 22, weight: .bold))
                        .foregroundStyle(dose.isTaken ? tint : Color.gray.opacity(0.5))
                        .rotationEffect(.degrees(dose.isTaken ? 0 : -45))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(dose.medicationName)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.primary.opacity(0.8))

                        Spacer()

                        Text(dose.timeLabel)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(dose.isTaken ? tint : Color.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        dose.isTaken
                                            ? tint.opacity(0.15)
                                            : isGraphite ? Color.white.opacity(0.05) : (colorScheme == .dark ? Color.black : Color.white).opacity(0.5)
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
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Color.gray)

                    Text(dose.isTaken ? "Tomada — toca para desmarcar" : "Pendiente — toca para marcar")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(dose.isTaken ? tint.opacity(0.8) : Color.gray.opacity(0.7))
                }
            }
            .padding(16)
            .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : (colorScheme == .dark ? Color.black : Color.white).opacity(0.5), lineWidth: 1))
            .shadow(color: Color.black.opacity(isGraphite ? (dose.isTaken ? 0.3 : 0.2) : (dose.isTaken ? 0.05 : 0.02)), radius: 10, y: dose.isTaken ? 4 : 2)
            .opacity(dose.isTaken ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
    }
}
