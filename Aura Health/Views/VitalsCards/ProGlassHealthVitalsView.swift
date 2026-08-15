import SwiftUI

struct ProGlassHealthVitalsView: View {
    @Bindable var store: MedicationStore
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    
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
                    VStack(spacing: 24) {
                        
                        formField(label: "Peso (kg)", type: .weight) {
                            proTextField("Ej: 75.5", text: $weight, keyboard: .decimalPad)
                        }
                        
                        formField(label: "Ritmo Cardíaco (bpm)", type: .heartRate) {
                            proTextField("Ej: 70", text: $heartRate, keyboard: .numberPad)
                        }
                        
                        formField(label: "Presión Arterial (mmHg)", type: .bloodPressureSystolic) {
                            HStack(spacing: 12) {
                                proTextField("Sistólica", text: $systolic, keyboard: .numberPad)
                                Text("/")
                                    .font(.title2.weight(.light))
                                    .foregroundStyle(.secondary)
                                proTextField("Diastólica", text: $diastolic, keyboard: .numberPad)
                            }
                        }
                        
                        formField(label: "Glucosa (mg/dL)", type: .glucose) {
                            proTextField("Ej: 95", text: $glucose, keyboard: .numberPad)
                        }
                        
                        formField(label: "Colesterol (mg/dL)", type: .cholesterol) {
                            proTextField("Ej: 180", text: $cholesterol, keyboard: .numberPad)
                        }
                        
                        formField(label: "Oxígeno en Sangre (%)", type: .bloodOxygen) {
                            proTextField("Ej: 98", text: $bloodOxygen, keyboard: .numberPad)
                        }
                        
                        formField(label: "Temperatura (°C)", type: .temperature) {
                            proTextField("Ej: 36.5", text: $temperature, keyboard: .decimalPad)
                        }
                        
                        formField(label: "HbA1c (%)", type: .hba1c) {
                            proTextField("Ej: 5.4", text: $hba1c, keyboard: .decimalPad)
                        }
                        
                        formField(label: "Nivel de Dolor (1-10)", type: .painLevel) {
                            proTextField("Ej: 4", text: $painLevel, keyboard: .numberPad)
                        }
                        
                        Button(action: saveVitals) {
                            Text("Guardar Mediciones")
                                .font(.system(.body, design: .rounded).weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    isGraphite
                                    ? LinearGradient(colors: [gold, Color(red: 0.75, green: 0.55, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                                    : isDark
                                    ? LinearGradient(colors: [Color.green.opacity(0.85), Color.mint.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundStyle(isGraphite ? Color.black.opacity(0.8) : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: isGraphite ? gold.opacity(0.4) : isDark ? Color.green.opacity(0.45) : Color.blue.opacity(0.3), radius: isGraphite ? 10 : 8, y: 4)
                        }
                        .padding(.top, 16)
                        
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Control de Salud")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundStyle(tint)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Historial") {
                        showingHistory = true
                    }
                    .foregroundStyle(tint)
                }
            }
            .sheet(isPresented: $showingHistory) {
                ProGlassVitalsHistoryView(store: store)
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
    
    private func proTextField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .padding(16)
            .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : Color.white.opacity(0.5), lineWidth: 1))
            .foregroundStyle(isGraphite ? Color.white : .primary)
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
    
    @ViewBuilder
    private func formField<Content: View>(label: String, type: HealthMetric.MetricType, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.gray)
                    .textCase(.uppercase)
                Spacer()
                if type.isPremium && !PremiumManager.shared.isPro {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(isGraphite ? gold.opacity(0.8) : tint)
                        .font(.caption)
                }
            }

            if type.isPremium && !PremiumManager.shared.isPro {
                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Text("Desbloquear con Aura Pro")
                            .foregroundStyle(isGraphite ? gold : tint)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                    .padding(16)
                    .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.02)) : AnyShapeStyle(.ultraThinMaterial))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isGraphite ? gold.opacity(0.1) : Color.gray.opacity(0.2), lineWidth: 1))
                }
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
