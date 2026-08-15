import SwiftUI

struct ProGlassNotificationSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    var store: MedicationStore
    
    @AppStorage("globalNotificationsEnabled") private var globalNotificationsEnabled: Bool = true
    @AppStorage("medNotificationsEnabled") private var medNotificationsEnabled: Bool = true
    @AppStorage("medAdvanceMins") private var medAdvanceMins: Int = 0
    @AppStorage("apptNotificationsEnabled") private var apptNotificationsEnabled: Bool = true
    
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    
    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)
    
    private var tint: Color {
        isGraphite ? gold : isDark ? Color.green : Color.blue
    }
    
    var body: some View {
        ZStack {
            glassBackground
            
            List {
                Section {
                    Toggle("Activar Notificaciones", isOn: $globalNotificationsEnabled)
                        .tint(tint)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(isGraphite ? .white : .primary)
                        .onChange(of: globalNotificationsEnabled) { _, _ in
                            reschedule()
                        }
                } header: {
                    Text("General")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("Desactiva esto para silenciar completamente la aplicación (modo No Molestar).")
                        .foregroundStyle(Color.gray)
                }
                .listRowBackground(isGraphite ? Color.white.opacity(0.05) : Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.7))
                
                if globalNotificationsEnabled {
                    Section {
                        Toggle("Recordatorios de Medicación", isOn: $medNotificationsEnabled)
                            .tint(tint)
                            .foregroundStyle(isGraphite ? .white : .primary)
                            .onChange(of: medNotificationsEnabled) { _, _ in reschedule() }
                        
                        if medNotificationsEnabled {
                            Picker("Aviso anticipado", selection: $medAdvanceMins) {
                                Text("A su hora en punto").tag(0)
                                Text("5 minutos antes").tag(5)
                                Text("10 minutos antes").tag(10)
                                Text("15 minutos antes").tag(15)
                                Text("30 minutos antes").tag(30)
                            }
                            .foregroundStyle(isGraphite ? .white : .primary)
                            .onChange(of: medAdvanceMins) { _, _ in reschedule() }
                        }
                    } header: {
                        Text("Medicación")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(isGraphite ? Color.white.opacity(0.05) : Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.7))
                    
                    Section {
                        Toggle("Avisos de Citas Médicas", isOn: $apptNotificationsEnabled)
                            .tint(tint)
                            .foregroundStyle(isGraphite ? .white : .primary)
                            .onChange(of: apptNotificationsEnabled) { _, _ in reschedule() }
                    } header: {
                        Text("Citas y Revisiones")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(isGraphite ? Color.white.opacity(0.05) : Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.7))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Notificaciones")
    }
    
    private func reschedule() {
        NotificationManager.shared.rescheduleAll(doses: store.doses, appointments: store.appointments, profiles: store.profiles)
    }
    
    private var glassBackground: some View {
        ZStack {
            if isGraphite {
                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            } else if colorScheme == .dark {
                Color.black.ignoresSafeArea()
                Circle().fill(Color.green.opacity(0.15)).frame(width: 300, height: 300).blur(radius: 80).offset(x: -100, y: -200)
                Circle().fill(Color.mint.opacity(0.15)).frame(width: 300, height: 300).blur(radius: 80).offset(x: 100, y: 200)
            } else {
                Color.white.ignoresSafeArea()
                Circle().fill(Color.blue.opacity(0.12)).frame(width: 300, height: 300).blur(radius: 60).offset(x: -150, y: -200)
                Circle().fill(Color.purple.opacity(0.12)).frame(width: 350, height: 350).blur(radius: 80).offset(x: 150, y: 150)
            }
        }
    }
}
