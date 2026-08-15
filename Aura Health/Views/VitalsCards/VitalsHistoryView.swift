import SwiftUI

struct VitalsHistoryView: View {
    @Bindable var store: MedicationStore
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: String = "Todos"
    
    private var vitalsForProfile: [HealthMetric] {
        guard let profileId = store.activeProfileId else { return [] }
        return store.allVitals
            .filter { $0.profileId == profileId }
            .sorted { $0.date > $1.date }
    }
    
    private var categories: [String] {
        var cats = ["Todos"]
        let uniqueTypes = Set(vitalsForProfile.map { $0.type.rawValue })
        cats.append(contentsOf: uniqueTypes.sorted())
        return cats
    }
    
    private var groupedVitals: [(Date, [HealthMetric])] {
        let filteredVitals = vitalsForProfile.filter { selectedCategory == "Todos" || $0.type.rawValue == selectedCategory }
        let grouped = Dictionary(grouping: filteredVitals) { vital in
            Calendar.current.startOfDay(for: vital.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        let str = formatter.string(from: date)
        return str.prefix(1).uppercased() + str.dropFirst()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatValue(_ vital: HealthMetric) -> String {
        "\(String(format: "%g", vital.value)) \(vital.unit)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()
                
                if vitalsForProfile.isEmpty {
                    VStack {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No hay mediciones registradas.")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                } else {
                    VStack(spacing: 0) {
                        Picker("Categoría", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        List {
                            ForEach(groupedVitals, id: \.0) { date, vitals in
                                Section(header: Text(formatDate(date))) {
                                    ForEach(vitals) { vital in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(vital.type.rawValue)
                                                    .font(.headline)
                                                    .foregroundColor(theme.textPrimary)
                                                Text(formatTime(vital.date))
                                                    .font(.caption)
                                                    .foregroundColor(theme.textSecondary)
                                            }
                                            Spacer()
                                            Text(formatValue(vital))
                                                .font(.system(.body, design: .rounded).weight(.bold))
                                                .foregroundColor(theme.accent)
                                        }
                                        .listRowBackground(theme.chipFill)
                                    }
                                    .onDelete { offsets in
                                        deleteVitals(offsets, in: vitals)
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .environment(\.locale, Locale(identifier: "es_ES"))
                    }
                }
            }
            .navigationTitle("Historial de Mediciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func deleteVitals(_ offsets: IndexSet, in sectionVitals: [HealthMetric]) {
        for index in offsets {
            let vitalToDelete = sectionVitals[index]
            if let storeIndex = store.allVitals.firstIndex(where: { $0.id == vitalToDelete.id }) {
                store.allVitals.remove(at: storeIndex)
            }
        }
        store.updateDerivedState()
        store.saveState()
    }
}
