//
//  StatisticsDetailView.swift
//  Aura Health
//

import SwiftUI
import Charts

struct StatisticsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    var store: MedicationStore
    
    @State private var rawSelectedDate: Date?

    private var selectedDayAdherence: MedicationStore.DailyAdherence? {
        guard let rawSelectedDate else { return nil }
        return store.mockAdherenceHistory.min(by: { abs($0.date.timeIntervalSince(rawSelectedDate)) < abs($1.date.timeIntervalSince(rawSelectedDate)) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary Header
                        HStack(spacing: 16) {
                            summaryCard(title: "Racha Actual", value: "\(store.currentStreakDays) días", icon: "flame.fill", color: .orange)
                            summaryCard(title: "Días Perfectos", value: "\(store.perfectDaysCount)", icon: "star.fill", color: .yellow)
                        }
                        .padding(.horizontal)
                        
                        // Chart Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Evolución últimos 7 días")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(theme.textPrimary)
                            
                            Chart {
                                ForEach(store.mockAdherenceHistory) { item in
                                    BarMark(
                                        x: .value("Día", item.date, unit: .day),
                                        y: .value("Cumplimiento", item.percentage * 100)
                                    )
                                    .foregroundStyle(item.percentage == 1.0 ? theme.accent.gradient : Color.gray.opacity(0.3).gradient)
                                    .cornerRadius(6)
                                }
                                
                                if let rawSelectedDate {
                                    RuleMark(x: .value("Seleccionado", rawSelectedDate, unit: .day))
                                        .foregroundStyle(theme.textSecondary.opacity(0.5))
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                }
                            }
                            .chartYAxis {
                                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let intValue = value.as(Int.self) {
                                            Text("\(intValue)%")
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
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
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(theme.chipFill)
                                    .shadow(color: theme.softShadow, radius: 8, y: 4)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Detalle del Día Seleccionado
                        if let selected = selectedDayAdherence {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Detalle del " + selected.date.formatted(.dateTime.weekday(.wide).day()))
                                        .font(.system(.headline, design: .rounded).weight(.bold))
                                        .foregroundStyle(theme.textPrimary)
                                    Spacer()
                                    Text("\(Int(selected.percentage * 100))%")
                                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        .foregroundStyle(selected.percentage == 1.0 ? theme.accent : Color.orange)
                                }
                                
                                if selected.percentage == 1.0 {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(theme.accent)
                                        Text("Todo al día 🎉")
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Dosis olvidadas:")
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundStyle(Color.red)
                                        ForEach(selected.missedMedications, id: \.self) { med in
                                            HStack {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(Color.red.opacity(0.8))
                                                Text(med)
                                                    .font(.system(.subheadline, design: .rounded))
                                                    .foregroundStyle(theme.textSecondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(selected.percentage == 1.0 ? theme.accent.opacity(0.5) : Color.red.opacity(0.5), lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.chipFill))
                            )
                            .padding(.horizontal)
                        }
                        
                        // Breakdown Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Desglose Histórico por Medicación")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(theme.textPrimary)
                            
                            VStack(spacing: 0) {
                                ForEach(store.mockMedicationBreakdown) { item in
                                    HStack {
                                        Image(systemName: "pill.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(theme.accent)
                                        
                                        Text(item.name)
                                            .font(.system(.body, design: .rounded).weight(.medium))
                                            .foregroundStyle(theme.textPrimary)
                                        
                                        Spacer()
                                        
                                        Text("\(item.totalDoses) tomas")
                                            .font(.system(.callout, design: .rounded).weight(.bold))
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                    .padding()
                                    
                                    if item.id != store.mockMedicationBreakdown.last?.id {
                                        Divider()
                                            .padding(.leading, 50)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(theme.chipFill)
                                    .shadow(color: theme.softShadow, radius: 8, y: 4)
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundStyle(theme.accent)
                }
            }
        }
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                    .textCase(.uppercase)
            }
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.chipFill)
                .shadow(color: theme.softShadow, radius: 8, y: 4)
        )
    }
}

#Preview {
    StatisticsDetailView(store: MedicationStore())
}
