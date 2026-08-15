//
//  NotificationSettingsView.swift
//  Aura Health
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.appTheme) private var theme
    var store: MedicationStore
    
    @AppStorage("globalNotificationsEnabled") private var globalNotificationsEnabled: Bool = true
    @AppStorage("medNotificationsEnabled") private var medNotificationsEnabled: Bool = true
    @AppStorage("medAdvanceMins") private var medAdvanceMins: Int = 0
    @AppStorage("apptNotificationsEnabled") private var apptNotificationsEnabled: Bool = true
    
    var body: some View {
        ZStack {
            OptimalBackground()
            
            List {
                Section {
                    Toggle("Activar Notificaciones", isOn: $globalNotificationsEnabled)
                        .tint(theme.accent)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .onChange(of: globalNotificationsEnabled) { _, _ in
                            reschedule()
                        }
                } header: {
                    Text("General")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                } footer: {
                    Text("Desactiva esto para silenciar completamente la aplicación (modo No Molestar).")
                        .foregroundStyle(theme.textSecondary)
                }
                .listRowBackground(theme.chipFill)
                
                if globalNotificationsEnabled {
                    Section {
                        Toggle("Recordatorios de Medicación", isOn: $medNotificationsEnabled)
                            .tint(theme.accent)
                            .onChange(of: medNotificationsEnabled) { _, _ in reschedule() }
                        
                        if medNotificationsEnabled {
                            Picker("Aviso anticipado", selection: $medAdvanceMins) {
                                Text("A su hora en punto").tag(0)
                                Text("5 minutos antes").tag(5)
                                Text("10 minutos antes").tag(10)
                                Text("15 minutos antes").tag(15)
                                Text("30 minutos antes").tag(30)
                            }
                            .onChange(of: medAdvanceMins) { _, _ in reschedule() }
                        }
                    } header: {
                        Text("Medicación")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .listRowBackground(theme.chipFill)
                    
                    Section {
                        Toggle("Avisos de Citas Médicas", isOn: $apptNotificationsEnabled)
                            .tint(theme.accent)
                            .onChange(of: apptNotificationsEnabled) { _, _ in reschedule() }
                    } header: {
                        Text("Citas y Revisiones")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .listRowBackground(theme.chipFill)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Notificaciones")
        .foregroundStyle(theme.textPrimary)
    }
    
    private func reschedule() {
        NotificationManager.shared.rescheduleAll(doses: store.doses, appointments: store.appointments, profiles: store.profiles)
    }
}
