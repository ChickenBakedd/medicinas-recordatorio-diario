import SwiftUI

struct HealthVitalsView: View {
    @Bindable var store: MedicationStore
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var weight: String = ""
    @State private var heartRate: String = ""
    @State private var glucose: String = ""
    @State private var systolic: String = ""
    @State private var diastolic: String = ""
    @State private var cholesterol: String = ""
    @State private var bloodOxygen: String = ""
    @State private var temperature: String = ""
    @State private var hba1c: String = ""
    @State private var painLevel: String = ""
    
    @State private var showingHistory: Bool = false
    @State private var showingPaywall: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()
                
                Form {
                    premiumSection(header: "Peso (kg)", type: .weight) {
                        TextField("Ej: 75.5", text: $weight)
                            .keyboardType(.decimalPad)
                    }
                    
                    premiumSection(header: "Ritmo Cardíaco (bpm)", type: .heartRate) {
                        TextField("Ej: 70", text: $heartRate)
                            .keyboardType(.numberPad)
                    }
                    
                    premiumSection(header: "Presión Arterial (mmHg)", type: .bloodPressureSystolic) {
                        HStack {
                            TextField("Sistólica", text: $systolic)
                                .keyboardType(.numberPad)
                            Text("/")
                            TextField("Diastólica", text: $diastolic)
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    premiumSection(header: "Glucosa (mg/dL)", type: .glucose) {
                        TextField("Ej: 95", text: $glucose)
                            .keyboardType(.numberPad)
                    }
                    
                    premiumSection(header: "Colesterol (mg/dL)", type: .cholesterol) {
                        TextField("Ej: 180", text: $cholesterol)
                            .keyboardType(.numberPad)
                    }
                    
                    premiumSection(header: "Oxígeno en Sangre (%)", type: .bloodOxygen) {
                        TextField("Ej: 98", text: $bloodOxygen)
                            .keyboardType(.numberPad)
                    }
                    
                    premiumSection(header: "Temperatura (°C)", type: .temperature) {
                        TextField("Ej: 36.5", text: $temperature)
                            .keyboardType(.decimalPad)
                    }
                    
                    premiumSection(header: "HbA1c (%)", type: .hba1c) {
                        TextField("Ej: 5.4", text: $hba1c)
                            .keyboardType(.decimalPad)
                    }
                    
                    premiumSection(header: "Nivel de Dolor (1-10)", type: .painLevel) {
                        TextField("Ej: 4", text: $painLevel)
                            .keyboardType(.numberPad)
                    }
                    
                    Section {
                        Button(action: saveVitals) {
                            Text("Guardar Mediciones")
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Control de Salud")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Historial") {
                        showingHistory = true
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                VitalsHistoryView(store: store)
                    .environment(\.appTheme, theme)
                    .applyThemeMode()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await HealthKitManager.shared.requestAuthorization()
            }
            .applyThemeMode()
        }
    }
    
    @ViewBuilder
    private func premiumSection<Content: View>(header: String, type: HealthMetric.MetricType, @ViewBuilder content: () -> Content) -> some View {
        Section(header: HStack {
            Text(header)
            if type.isPremium && !PremiumManager.shared.isPro {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray)
            }
        }) {
            if type.isPremium && !PremiumManager.shared.isPro {
                Button("Desbloquear con Versión PRO") {
                    showingPaywall = true
                }
                .foregroundStyle(.blue)
            } else {
                content()
            }
        }
    }
    
    private func saveVitals() {
        guard let profileId = store.activeProfileId else { return }
        let now = Date()
        
        func saveIfValid(_ valStr: String, type: HealthMetric.MetricType) {
            let normalized = valStr.replacingOccurrences(of: ",", with: ".")
            if let v = Double(normalized), v >= 0 {
                if type == .painLevel && v > 10 { return }
                if type == .bloodOxygen && v > 100 { return }
                if type == .heartRate && v > 300 { return }
                if type == .temperature && (v < 30 || v > 45) { return }
                
                let metric = HealthMetric(profileId: profileId, type: type, value: v, date: now, unit: type.defaultUnit)
                store.addVital(metric)
                Task { await HealthKitManager.shared.saveMetric(metric) }
            }
        }
        
        saveIfValid(weight, type: .weight)
        saveIfValid(heartRate, type: .heartRate)
        saveIfValid(systolic, type: .bloodPressureSystolic)
        saveIfValid(diastolic, type: .bloodPressureDiastolic)
        saveIfValid(glucose, type: .glucose)
        saveIfValid(cholesterol, type: .cholesterol)
        saveIfValid(bloodOxygen, type: .bloodOxygen)
        saveIfValid(temperature, type: .temperature)
        saveIfValid(hba1c, type: .hba1c)
        saveIfValid(painLevel, type: .painLevel)
        
        weight = ""
        heartRate = ""
        glucose = ""
        systolic = ""
        diastolic = ""
        cholesterol = ""
        bloodOxygen = ""
        temperature = ""
        hba1c = ""
        painLevel = ""
        
        dismiss()
    }
}
