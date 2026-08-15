import SwiftUI

struct MedicalReportView: View {
    var store: MedicationStore
    
    private var activeProfile: UserProfile? {
        store.profiles.first(where: { $0.id == store.activeProfileId })
    }
    
    // Group doses by medication name to avoid duplicates in the report
    private var activeMedications: [String: [MedicationDose]] {
        Dictionary(grouping: store.doses, by: { $0.medicationName })
    }
    
    private var sortedMedicationNames: [String] {
        activeMedications.keys.sorted()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header with Blue background
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("INFORME MÉDICO")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .tracking(2)
                    
                    Text("HISTORIAL CLÍNICO")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                    
                    if let profile = activeProfile {
                        Text("Paciente: \(profile.name)")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white)
                            .padding(.top, 4)
                            
                        if !profile.medicalConditions.isEmpty {
                            Text("Condiciones: \(profile.medicalConditions.joined(separator: ", "))")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                    }
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.white)
                        .padding(.bottom, 8)
                    
                    Text("Fecha de emisión")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Text(dateFormatter.string(from: Date()))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(40)
            .background(Color.blue)
            
            VStack(alignment: .leading, spacing: 30) {
                
                // Dashboard Stats
                HStack(spacing: 20) {
                    let total = store.totalDosesTakenAllTime
                    let adherence = total > 0 ? ">90%" : "N/A"
                    statBox(title: "Adherencia (Est.)", value: adherence, icon: "chart.line.uptrend.xyaxis")
                    statBox(title: "Tomas Exitosas", value: "\(total)", icon: "checkmark.circle.fill")
                    statBox(title: "Días Perfectos", value: "\(store.perfectDaysCount)", icon: "star.fill")
                }
                .padding(.vertical, 10)
                
                Divider()
                
                // Medication Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("Tratamiento Activo", systemImage: "pills.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.blue)
                    
                    if sortedMedicationNames.isEmpty {
                        Text("No hay medicación registrada.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gray)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(sortedMedicationNames, id: \.self) { name in
                                if let doses = activeMedications[name], let firstDose = doses.first {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(name)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(Color.black)
                                            
                                            if let mg = firstDose.milligrams {
                                                Text("\(mg) mg")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(Color.gray)
                                            }
                                        }
                                        .frame(width: 200, alignment: .leading)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack(spacing: 8) {
                                                ForEach(doses.sorted(by: { $0.scheduledTime < $1.scheduledTime })) { dose in
                                                    Text(dose.scheduledTime.formatted(.dateTime.hour().minute()))
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.blue.opacity(0.1))
                                                        .foregroundColor(Color.blue)
                                                        .cornerRadius(6)
                                                }
                                            }
                                            
                                            if let inventory = store.inventories[name] {
                                                Text("Inventario: \(String(format: "%g", inventory.currentStock)) unidades")
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundStyle(Color.gray)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    
                                    if name != sortedMedicationNames.last {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                }
                
                // Appointments Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("Próximas Citas Médicas", systemImage: "calendar.badge.clock")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.blue)
                    
                    if store.appointments.isEmpty {
                        Text("No hay citas programadas.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gray)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(store.appointments.sorted(by: { $0.date < $1.date })) { appt in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(appt.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.black)
                                        if let spec = appt.specialty, !spec.isEmpty {
                                            Text(spec)
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundStyle(Color.gray)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(appt.date.formatted(.dateTime.day().month().year().hour().minute()))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.black)
                                        if let notes = appt.notes, !notes.isEmpty {
                                            Text(notes)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundStyle(Color.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(.vertical, 12)
                                
                                if appt.id != store.appointments.sorted(by: { $0.date < $1.date }).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                }
                
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
    
    private func statBox(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.blue)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.gray)
            }
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
    }
}
