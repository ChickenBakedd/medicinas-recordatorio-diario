//
//  ProGlassHomeView.swift
//  Aura Health
//

import SwiftUI

struct ProGlassHomeView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @AppStorage("showGamification") private var showGamification: Bool = false
    @AppStorage("showHealthTips") private var showHealthTips: Bool = true
    @Bindable var store: MedicationStore
    @Binding var showSettings: Bool
    var onAddTap: (() -> Void)? = nil
    
    @State private var showDailyReview = false
    @State private var showStatistics = false
    @State private var animateBackground = false

    private var isDark: Bool { appThemeMode == "pureBlack" }
    private var isGraphite: Bool { appThemeMode == "graphite" }
    // Gold color used as accent in graphite mode
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)

    private var spanishDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE d 'de' MMMM 'de' yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
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
                            progressRingCard
                            
                            ConditionInsightCard(store: store)
                            
                            if !lowStockInventories.isEmpty {
                                stockWarnings
                            }
                            
                            nextDoseCard
                        }
                        
                        statsRow
                        
                        if let _ = upcomingAppointment {
                            nextAppointmentCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .padding(.top, 6)
        }
        .background {
            glassBackground
        }
        .sheet(isPresented: $showDailyReview) {
            ProGlassDailyDosesReviewView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
        .sheet(isPresented: $showStatistics) {
            ProGlassStatisticsView(store: store)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
        .onAppear {
            guard !animateBackground else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
        }
    }
    
    // MARK: - Glass Background
    private var glassBackground: some View {
        ZStack {
            if isGraphite {
                // Graphite: flat dark gray, no halos
                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            } else {
                (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: animateBackground ? 100 : -50, y: animateBackground ? -150 : -250)
                
                Circle()
                    .fill(Color.pink.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: animateBackground ? -100 : 150, y: animateBackground ? 200 : 100)
                
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: animateBackground ? 50 : 200, y: animateBackground ? 300 : 400)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Glass Card Modifier
    private struct GlassCardModifier: ViewModifier {
        var isDark: Bool
        var isGraphite: Bool
        func body(content: Content) -> some View {
            content
                .background(
                    isGraphite
                    ? AnyShapeStyle(Color.white.opacity(0.05))
                    : isDark ? AnyShapeStyle(Color.white.opacity(0.06)) : AnyShapeStyle(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            isGraphite ? Color(red: 0.85, green: 0.68, blue: 0.35).opacity(0.25)
                            : isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.5),
                            lineWidth: isGraphite ? 1 : 1
                        )
                )
                .shadow(color: Color.black.opacity(isGraphite ? 0.5 : isDark ? 0.4 : 0.05), radius: 15, x: 0, y: 8)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(spanishDate.capitalized.replacingOccurrences(of: " De ", with: " de "))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(isGraphite ? Color.white.opacity(0.45) : Color.gray)
                
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
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(isGraphite ? Color.white.opacity(0.9) : Color.primary.opacity(0.8))
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(isGraphite ? gold : Color.gray.opacity(0.5))
                    }
                }
            }
            Spacer()
            
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(isGraphite ? gold : Color.gray)
                    .padding(12)
                    .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.06)) : AnyShapeStyle(.ultraThinMaterial))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(isGraphite ? gold.opacity(0.4) : Color.white.opacity(0.6), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Progress Ring
    private var progressRingCard: some View {
        VStack(spacing: 20) {
            Text("Progreso de Hoy")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(isGraphite ? Color.white.opacity(0.5) : Color.primary.opacity(0.7))
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                
                Circle()
                    .trim(from: 0, to: CGFloat(store.progress))
                    .stroke(
                        isGraphite
                        ? LinearGradient(colors: [gold, Color(red: 0.75, green: 0.55, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : isDark
                        ? LinearGradient(colors: [Color.green, Color.mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: store.progress)
                
                VStack(spacing: 4) {
                    Text("\(Int(store.progress * 100))%")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(isGraphite ? gold : Color.primary.opacity(0.8))
                    
                    Text("\(store.takenDosesToday)/\(store.totalDosesToday) tomas")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Color.gray)
                }
            }
            .frame(height: 180)
            
            if store.takenDosesToday > 0 {
                Button {
                    showDailyReview = true
                } label: {
                    Text("Ver Registro Diario")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(isGraphite ? gold : isDark ? Color.green : Color.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            isGraphite ? gold.opacity(0.12)
                            : isDark ? Color.green.opacity(0.15)
                            : Color.blue.opacity(0.1)
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .modifier(GlassCardModifier(isDark: isDark, isGraphite: isGraphite))
    }

    // MARK: - Stats Row (hidden if gamification is off)
    private var statsRow: some View {
        Group {
            if showGamification {
                HStack(spacing: 16) {
                    Button {
                        showStatistics = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundStyle(Color.orange)
                            Text("Racha")
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(Color.gray)
                            Text("\(store.currentStreakDays) días")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.primary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .modifier(GlassCardModifier(isDark: isDark, isGraphite: false))
                    }
                    
                    Button {
                        showStatistics = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundStyle(Color.purple.opacity(0.7))
                            Text("Histórico")
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(Color.gray)
                            Text("\(store.totalDosesTakenAllTime) tomas")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.primary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .modifier(GlassCardModifier(isDark: isDark, isGraphite: false))
                    }
                }
            }
        }
    }

    // MARK: - Next Dose Card
    private var nextDoseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let dose = store.currentDose {
                HStack {
                    Text("Siguiente Toma")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(isGraphite ? Color.white.opacity(0.6) : Color.primary.opacity(0.8))
                    
                    Spacer()
                    
                    Text(dose.timeLabel)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isGraphite ? Color.white.opacity(0.15) : (isDark ? Color.mint.opacity(0.4) : Color.blue.opacity(0.8)))
                        )
                }
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(isGraphite
                                ? LinearGradient(colors: [gold.opacity(0.2), gold.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : isDark
                                ? LinearGradient(colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: dose.form == .pill ? "capsule.fill" : "cross.vial.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(isGraphite ? gold : isDark ? Color.green : Color.blue)
                            .rotationEffect(.degrees(dose.form == .pill ? -45 : 0))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dose.medicationName)
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(isGraphite ? Color.white.opacity(0.9) : Color.primary.opacity(0.8))
                        
                        if let mg = dose.milligrams {
                            Text("\(mg) mg • \(dose.amount.rawValue)")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color.gray)
                        } else {
                            Text(dose.amount.rawValue)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    Spacer()
                }
                
                Button {
                    HapticManager.shared.notification(type: .success)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        store.registerCurrentDose()
                    }
                } label: {
                    Text("Registrar Toma")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            isGraphite
                            ? LinearGradient(colors: [gold, Color(red: 0.75, green: 0.55, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                            : isDark
                            ? LinearGradient(colors: [Color.green.opacity(0.85), Color.mint.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(isGraphite ? Color.black.opacity(0.8) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: isGraphite ? gold.opacity(0.4) : isDark ? Color.green.opacity(0.45) : Color.blue.opacity(0.3), radius: isGraphite ? 10 : isDark ? 12 : 8, y: 4)
                }
                .buttonStyle(.plain)
                
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(isGraphite ? gold : Color.green.opacity(0.8))
                    
                    Text("¡Todo al día!")
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(isGraphite ? Color.white.opacity(0.4) : Color.primary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(24)
        .modifier(GlassCardModifier(isDark: isDark, isGraphite: isGraphite))
    }

    // MARK: - Stock Warnings
    private var lowStockInventories: [MedicationInventory] {
        Array(store.inventories.values).filter { $0.currentStock <= $0.lowStockThreshold }
            .sorted { $0.medicationName < $1.medicationName }
    }
    
    private var stockWarnings: some View {
        VStack(spacing: 8) {
            ForEach(lowStockInventories, id: \.medicationName) { inv in
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.red.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(inv.medicationName) casi agotado")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(isGraphite ? Color.white.opacity(0.85) : Color.primary.opacity(0.8))
                        Text("Quedan \(String(format: "%g", inv.currentStock)) unidades")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.gray)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.red.opacity(isDark || isGraphite ? 0.12 : 0.05))
                .modifier(GlassCardModifier(isDark: isDark, isGraphite: isGraphite))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Next Appointment Card
    private var upcomingAppointment: MedicalAppointment? {
        store.appointmentsSortedByDate.first(where: { $0.date > Date() })
    }

    private var nextAppointmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Próxima Cita")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(isGraphite ? Color.white.opacity(0.5) : Color.primary.opacity(0.7))
            
            if let appointment = upcomingAppointment {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(isGraphite
                                ? LinearGradient(colors: [gold.opacity(0.2), gold.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : isDark
                                ? LinearGradient(colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 24))
                            .foregroundStyle(isGraphite ? gold : isDark ? Color.green : Color.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.title)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(isGraphite ? Color.white.opacity(0.9) : Color.primary.opacity(0.8))
                        
                        Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray)
                        
                        if let specialty = appointment.specialty, !specialty.isEmpty {
                            Text(specialty)
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(isGraphite ? gold : isDark ? Color.green : Color.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill((isGraphite ? gold : isDark ? Color.green : Color.blue).opacity(0.15))
                                )
                                .padding(.top, 4)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(24)
        .modifier(GlassCardModifier(isDark: isDark, isGraphite: isGraphite))
    }
}
