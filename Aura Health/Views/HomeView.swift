//
//  HomeView.swift
//  Aura Health
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showGamification") private var showGamification: Bool = false
    @AppStorage("showHealthTips") private var showHealthTips: Bool = true
    @Environment(\.appTheme) private var theme
    @Bindable var store: MedicationStore
    @Binding var showSettings: Bool
    var onAddTap: (() -> Void)? = nil
    @State private var showDailyReview = false
    @State private var showStatistics = false

    private var spanishDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE d 'de' MMMM 'de' yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if showHealthTips {
                        HealthTipsCarouselView()
                    }

                    if store.doses.isEmpty {
                        EmptyMedicationsView(
                            store: store,
                            onAddMedication: { onAddTap?() },
                            onImportHealth: { }
                        )
                        .padding(.top, 40)
                    } else {
                        progressSection
                        
                        ConditionInsightCard(store: store)
                        
                        if !lowStockInventories.isEmpty {
                            stockWarnings
                        }

                        currentDoseCard
                    }
                    
                    if showGamification {
                        statsSection
                    }
                    
                    if !store.appointments.filter({ $0.date > Date() }).isEmpty {
                        appointmentsCard
                    }
                }
                .padding(.bottom, 100) // Padding for bottom bar
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .sheet(isPresented: $showDailyReview) {
            DailyDosesReviewView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
        .sheet(isPresented: $showStatistics) {
            StatisticsDetailView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Menu {
                    ForEach(store.profiles) { profile in
                        Button {
                            store.activeProfileId = profile.id
                            store.updateDerivedState()
                        } label: {
                            HStack {
                                Text(profile.name)
                                if store.activeProfileId == profile.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(store.activeProfile?.name ?? "Optimal")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.textPrimary)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(theme.accent)
                    }
                }

                HStack {
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body)
                            .foregroundStyle(theme.accent.opacity(0.85))
                            .padding(10)
                            .background(Circle().fill(theme.chipFill))
                            .shadow(color: theme.softShadow, radius: 4, y: 2)
                    }
                }
            }

            Text(spanishDate.capitalized.replacingOccurrences(of: " De ", with: " de "))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(theme.chipFill)
                        .shadow(color: theme.softShadow, radius: 3, y: 1)
                )
        }
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(theme.trackGray.opacity(0.55))
                        .frame(height: 18)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.accent.opacity(0.85), theme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(18, geometry.size.width * store.progress), height: 18)
                        .shadow(color: theme.accent.opacity(0.35), radius: 4, y: 2)
                        .animation(.easeInOut(duration: 0.35), value: store.progress)
                }
            }
            .frame(height: 18)

            HStack {
                Text("Llevas \(store.takenDosesToday) de \(store.totalDosesToday) medicinas hoy")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(theme.textSecondary)

                Spacer()

                if store.takenDosesToday > 0 {
                    Button {
                        showDailyReview = true
                    } label: {
                        Label("Ver tomas", systemImage: "list.bullet")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(theme.chipFill)
                                    .shadow(color: theme.softShadow, radius: 3, y: 1)
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(theme.accent.opacity(0.35), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            // Racha
            Button {
                showStatistics = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Color.orange)
                        Text("Racha Actual")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.textSecondary)
                            .textCase(.uppercase)
                    }
                    Text("\(store.currentStreakDays) días")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.chipFill)
                        .shadow(color: theme.softShadow, radius: 4, y: 2)
                )
            }
            .buttonStyle(.plain)

            // Dosis totales
            Button {
                showStatistics = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "pill.fill")
                            .foregroundStyle(theme.accent)
                        Text("Histórico")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.textSecondary)
                            .textCase(.uppercase)
                    }
                    Text("\(store.totalDosesTakenAllTime) tomas")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.chipFill)
                        .shadow(color: theme.softShadow, radius: 4, y: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var lowStockInventories: [MedicationInventory] {
        Array(store.inventories.values).filter { $0.currentStock <= $0.lowStockThreshold }
            .sorted { $0.medicationName < $1.medicationName }
    }

    private var stockWarnings: some View {
        VStack(spacing: 8) {
            ForEach(lowStockInventories, id: \.medicationName) { inv in
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aviso de stock: \(inv.medicationName)")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.textPrimary)
                        Text("Te quedan \(String(format: "%g", inv.currentStock)) unidades")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.yellow.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }

    private var currentDoseCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let dose = store.currentDose {
                HStack {
                    Text("Toma actual")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.accent)

                    Spacer()

                    Text(dose.timeLabel)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.accent.opacity(0.9))
                        )
                }
                .padding(.bottom, 18)

                Spacer(minLength: 12)

                HStack(alignment: .center, spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.accent.opacity(0.18),
                                        theme.accent.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)

                        Image(systemName: dose.form == .pill ? "capsule.fill" : "cross.vial.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(theme.accent)
                            .rotationEffect(.degrees(dose.form == .pill ? -45 : 0))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(dose.medicationName)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.textPrimary)

                        if let mg = dose.milligrams {
                            Text("\(mg) mg")
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .foregroundStyle(theme.textSecondary)
                        }

                        Text(dose.amount.rawValue)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(theme.chipFill)
                            )
                    }
                }

                Spacer(minLength: 20)

                Button {
                    HapticManager.shared.notification(type: .success)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        store.registerCurrentDose()
                    }
                } label: {
                    Text("Toca para registrar la toma")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            theme.accent.opacity(0.75),
                                            theme.accent
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: theme.accent.opacity(0.35), radius: 6, y: 3)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(theme.success)

                    Text("¡Has completado todas las tomas de hoy!")
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.textSecondary)

                    Button {
                        showDailyReview = true
                    } label: {
                        Label("Revisar tomas de hoy", systemImage: "arrow.counterclockwise")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(theme.chipFill)
                                    .shadow(color: theme.softShadow, radius: 4, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(theme.accent.opacity(0.35), lineWidth: 1.5)
                            )
                            .foregroundStyle(theme.accent)
                    }
                    .buttonStyle(.plain)

                    Text("Por si te has equivocado al marcar alguna toma")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.textMuted)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .remindMyCard(fill: theme.doseCard)
    }

    private var appointmentsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(theme.accent)

                Text("Próximas citas médicas")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                let upcoming = store.appointments.filter { $0.date > Date() }.sorted { $0.date < $1.date }
                ForEach(upcoming) { appointment in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(theme.accent.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)

                        Text(appointment.displayText)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .remindMyCard(fill: theme.appointmentsCard, cornerRadius: 18)
    }
}

#Preview {
    HomeView(store: MedicationStore(), showSettings: .constant(false))
}
