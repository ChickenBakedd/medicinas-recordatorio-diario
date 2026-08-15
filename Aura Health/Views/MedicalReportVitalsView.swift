import SwiftUI

struct MedicalReportVitalsView: View {
    var store: MedicationStore
    
    private var activeProfile: UserProfile? {
        store.profiles.first(where: { $0.id == store.activeProfileId })
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }
    
    private func calculateAverage(type: HealthMetric.MetricType, days: Int) -> String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let metrics = store.vitals.filter { $0.type == type && $0.date >= cutoff }
        if metrics.isEmpty { return "-" }
        let sum = metrics.reduce(0) { $0 + $1.value }
        let avg = sum / Double(metrics.count)
        
        if type == .bloodPressureSystolic || type == .bloodPressureDiastolic || type == .glucose {
            return String(format: "%.0f", avg)
        }
        return String(format: "%.1f", avg)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("INFORME MÉDICO")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .tracking(2)
                    
                    Text("CONTROL DE SALUD")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                    
                    if let profile = activeProfile {
                        Text("Paciente: \(profile.name)")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white)
                            .padding(.top, 4)
                    }
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.white)
                        .padding(.bottom, 8)
                    
                    Text("Constantes Vitales")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(40)
            .background(Color.red)
            
            VStack(alignment: .leading, spacing: 30) {
                Text("Resumen Estadístico (Medias Móviles)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.red)
                    .padding(.top, 10)
                
                // Vitals Table
                VStack(spacing: 0) {
                    // Table Header
                    HStack {
                        Text("Métrica")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("7 Días")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 80, alignment: .center)
                        Text("15 Días")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 80, alignment: .center)
                        Text("30 Días")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 80, alignment: .center)
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.1))
                    
                    Divider()
                    
                    vitalRow(title: "Peso (kg)", icon: "scalemass", type: .weight)
                    Divider()
                    vitalRow(title: "Glucosa (mg/dL)", icon: "drop.fill", type: .glucose)
                    Divider()
                    vitalRow(title: "P. Sistólica (mmHg)", icon: "heart.fill", type: .bloodPressureSystolic)
                    Divider()
                    vitalRow(title: "P. Diastólica (mmHg)", icon: "heart", type: .bloodPressureDiastolic)
                }
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Divider()
                    Text("Este documento tiene carácter informativo y fue generado automáticamente. No sustituye la opinión de un profesional médico.")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
        }
        .frame(width: 595, height: 842)
        .background(Color.white)
    }
    
    private func vitalRow(title: String, icon: String, type: HealthMetric.MetricType) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(calculateAverage(type: type, days: 7))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .center)
            
            Text(calculateAverage(type: type, days: 15))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .center)
                
            Text(calculateAverage(type: type, days: 30))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .center)
        }
        .padding(16)
        .background(Color.white)
    }
}
