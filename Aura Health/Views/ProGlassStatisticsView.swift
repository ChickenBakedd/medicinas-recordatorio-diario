//
//  ProGlassStatisticsView.swift
//  Aura Health
//

import SwiftUI
import Charts

struct ProGlassStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    var store: MedicationStore
    
    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)
    
    @State private var rawSelectedDate: Date?

    private var selectedDayAdherence: MedicationStore.DailyAdherence? {
        guard let rawSelectedDate else { return nil }
        return store.mockAdherenceHistory.min(by: { abs($0.date.timeIntervalSince(rawSelectedDate)) < abs($1.date.timeIntervalSince(rawSelectedDate)) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                glassBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Summary Header
                        HStack(spacing: 16) {
                            summaryCard(title: "Racha Actual", value: "\(store.currentStreakDays) días", icon: "flame.fill", color: isGraphite ? gold : isDark ? Color.green : .orange)
                            summaryCard(title: "Días Perfectos", value: "\(store.perfectDaysCount)", icon: "star.fill", color: isGraphite ? gold : isDark ? Color.mint : .yellow)
                        }
                        .padding(.horizontal, 20)
                        
                        // Chart Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Evolución últimos 7 días")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.primary.opacity(0.8))
                            
                            Chart {
                                ForEach(store.mockAdherenceHistory) { item in
                                    BarMark(
                                        x: .value("Día", item.date, unit: .day),
                                        y: .value("Cumplimiento", item.percentage * 100)
                                    )
                                     .foregroundStyle(gradient(for: item.percentage))
                                    .cornerRadius(6)
                                }
                                
                                if let rawSelectedDate {
                                    RuleMark(x: .value("Seleccionado", rawSelectedDate, unit: .day))
                                        .foregroundStyle(Color.gray.opacity(0.5))
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                }
                            }
                            .chartYAxis {
                                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4])).foregroundStyle(Color.gray.opacity(0.2))
                                    AxisValueLabel {
                                        if let intValue = value.as(Int.self) {
                                            Text("\(intValue)%").font(.system(.caption2, design: .rounded)).foregroundStyle(Color.gray)
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated)).font(.system(.caption2, design: .rounded)).foregroundStyle(Color.gray)
                                }
                            }
                            .chartOverlay { proxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    if let plotFrame = proxy.plotFrame {
                                                        let x = value.location.x - geometry[plotFrame].origin.x
                                                        if let date: Date = proxy.value(atX: x) {
                                                            rawSelectedDate = date
                                                        }
                                                    }
                                                }
                                        )
                                }
                            }
                            .frame(height: 250)
                            .padding(20)
                            .background(chartBackgroundStyle)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(chartStrokeStyle, lineWidth: 1)
                            )
                            .shadow(color: chartShadowColor, radius: 15, y: 5)
                        }
                        .padding(.horizontal, 20)
                        
                        // Detalle del Día Seleccionado
                        if let selected = selectedDayAdherence {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Detalle del " + selected.date.formatted(.dateTime.weekday(.wide).day()))
                                        .font(.system(.headline, design: .rounded).weight(.bold))
                                        .foregroundStyle(Color.primary.opacity(0.8))
                                    Spacer()
                                    Text("\(Int(selected.percentage * 100))%")
                                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        .foregroundStyle(selected.percentage == 1.0 ? Color.blue : Color.orange)
                                }
                                
                                if selected.percentage == 1.0 {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.title3)
                                            .foregroundStyle(Color.blue)
                                        Text("Todo al día 🎉")
                                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                                            .foregroundStyle(Color.gray)
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Dosis olvidadas:")
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundStyle(Color.red.opacity(0.9))
                                        ForEach(selected.missedMedications, id: \.self) { med in
                                            HStack(spacing: 8) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(Color.red.opacity(0.8))
                                                Text(med)
                                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                                                    .foregroundStyle(Color.gray)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(selected.percentage == 1.0 ? (isGraphite ? gold : isDark ? Color.green : Color.blue).opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(isGraphite ? 0.3 : 0.05), radius: 10, y: 4)
                            .padding(.horizontal, 20)
                        }
                        
                        // Breakdown Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Desglose Histórico")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.primary.opacity(0.8))
                            
                            VStack(spacing: 0) {
                                ForEach(store.mockMedicationBreakdown) { item in
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill((isGraphite ? gold : isDark ? Color.green : Color.purple).opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "pill.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(isGraphite ? gold : isDark ? Color.green : Color.purple)
                                        }
                                        
                                        Text(item.name)
                                            .font(.system(.body, design: .rounded).weight(.semibold))
                                            .foregroundStyle(Color.primary.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("\(item.totalDoses) tomas")
                                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                                            .foregroundStyle(Color.gray)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    
                                    if item.id != store.mockMedicationBreakdown.last?.id {
                                        Divider()
                                            .padding(.leading, 64)
                                            .opacity(0.5)
                                    }
                                }
                            }
                            .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : (colorScheme == .dark ? Color.black : Color.white).opacity(0.5), lineWidth: 1))
                            .shadow(color: Color.black.opacity(isGraphite ? 0.3 : 0.05), radius: 15, y: 5)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Estadísticas Pro")
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
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -250)
                
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: 150, y: 100)
            }
        }
        .ignoresSafeArea()
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.primary.opacity(0.8))
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Color.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : (colorScheme == .dark ? Color.black : Color.white).opacity(0.5), lineWidth: 1))
        .shadow(color: Color.black.opacity(isGraphite ? 0.3 : 0.05), radius: 10, y: 4)
    }

    private func gradient(for percentage: Double) -> LinearGradient {
        if percentage == 1.0 {
            let colors = isGraphite ? [gold, gold.opacity(0.7)] : isDark ? [Color.green, Color.mint] : [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]
            return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
        } else {
            let colors = [Color.gray.opacity(isGraphite ? 0.2 : 0.4), Color.gray.opacity(isGraphite ? 0.1 : 0.2)]
            return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
        }
    }

    private var chartBackgroundStyle: AnyShapeStyle {
        isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial)
    }

    private var chartStrokeStyle: AnyShapeStyle {
        if isGraphite { return AnyShapeStyle(gold.opacity(0.2)) }
        if isDark { return AnyShapeStyle(Color.green.opacity(0.2)) }
        return AnyShapeStyle((colorScheme == .dark ? Color.black : Color.white).opacity(0.5))
    }

    private var chartShadowColor: Color {
        Color.black.opacity(isGraphite ? 0.3 : 0.05)
    }
}
