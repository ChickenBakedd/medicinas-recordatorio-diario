//
//  AppSettingsView.swift
//  Aura Health
//

import SwiftUI

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @AppStorage("appUIStyle") private var appUIStyle: String = "classic"
    @AppStorage("requireFaceID") private var requireFaceID: Bool = false
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("showGamification") private var showGamification: Bool = false
    @AppStorage("showHealthTips") private var showHealthTips: Bool = true

    @State private var showingPaywall = false
    @Bindable var store: MedicationStore
    @ObservedObject private var backupManager = CloudBackupManager.shared
    
    private var activeColorScheme: ColorScheme? {
        if appThemeMode == "light" { return .light }
        if appThemeMode == "pureBlack" { return .dark }
        if appThemeMode == "graphite" { return .dark }
        if appThemeMode == "blueDark" { return .dark }
        return nil
    }
    
    private var uiStyleBinding: Binding<String> {
        Binding(
            get: { appUIStyle },
            set: { newValue in
                if newValue == "proGlass" && !PremiumManager.shared.isPro {
                    showingPaywall = true
                } else {
                    appUIStyle = newValue
                    if newValue == "proGlass" && (appThemeMode == "system" || appThemeMode == "blueDark") {
                        appThemeMode = "light"
                        UserDefaults(suiteName: "group.com.jmrsoft.medicinas")?.set("light", forKey: "appThemeMode")
                    }
                }
            }
        )
    }
    
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var isGeneratingPDF = false
    
    @State private var showingBackupAlert = false
    @State private var backupAlertTitle = ""
    @State private var backupAlertMessage = ""

    @State private var showingRestoreAlert = false
    @State private var restoreAlertTitle = ""
    @State private var restoreAlertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()
                List {
                    Section {
                        Button(action: { appThemeMode = "light" }) {
                            HStack {
                                Label("Claro", systemImage: "sun.max.fill")
                                    .foregroundStyle(Color.orange)
                                Spacer()
                                if appThemeMode == "light" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.accent)
                                }
                            }
                            .foregroundStyle(theme.textPrimary)
                        }
                        Button(action: { appThemeMode = "pureBlack" }) {
                            HStack {
                                Label("Oscuro (Negro Puro)", systemImage: "moon.fill")
                                    .foregroundStyle(Color.gray)
                                Spacer()
                                if appThemeMode == "pureBlack" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.accent)
                                }
                            }
                            .foregroundStyle(theme.textPrimary)
                        }
                        Button(action: { appThemeMode = "blueDark" }) {
                            HStack {
                                Label("Oscuro (Azulado)", systemImage: "moon.stars.fill")
                                    .foregroundStyle(Color.blue)
                                Spacer()
                                if appThemeMode == "blueDark" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.accent)
                                }
                            }
                            .foregroundStyle(theme.textPrimary)
                        }
                    } header: {
                        Label("Apariencia", systemImage: "paintpalette.fill")
                            .foregroundStyle(theme.textSecondary)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .textCase(nil)
                    }
                    .listRowBackground(theme.chipFill)
                    
                    Section {
                        NavigationLink(destination: ProfilesSettingsView(store: store)) {
                            HStack {
                                Label("Perfiles Familiares", systemImage: "person.2.fill")
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                if !PremiumManager.shared.isPro {
                                    Text("\(store.profiles.count)/2 gratis")
                                        .font(.system(.caption, design: .rounded).weight(.medium))
                                        .foregroundStyle(theme.textSecondary)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 10))
                                        Text("Ilimitados")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange))
                                }
                            }
                        }
                    } header: {
                        Label("Familia", systemImage: "house.fill")
                            .foregroundStyle(theme.textSecondary)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .textCase(nil)
                    } footer: {
                        Text("Gestiona hasta 2 perfiles en la versión gratuita o perfiles ilimitados con la versión PRO.")
                    }
                    .listRowBackground(theme.chipFill)

                    Section {
                        Picker("Interfaz de la App", selection: uiStyleBinding) {
                            Text("Clásica (Gratis)").tag("classic")
                            Text("Glass PRO ✨").tag("proGlass")
                        }
                        .pickerStyle(.navigationLink)
                        .foregroundStyle(theme.textPrimary)

                        if !PremiumManager.shared.isPro {
                            Button(action: { showingPaywall = true }) {
                                Text("Mejorar a Versión PRO ✨")
                                    .foregroundStyle(Color.yellow)
                                    .fontWeight(.bold)
                            }
                            
                            Button(action: { 
                                PremiumManager.shared.restorePurchases { success in
                                    if success {
                                        restoreAlertTitle = "Compras Restauradas"
                                        restoreAlertMessage = "Se han restaurado tus compras exitosamente. Ya puedes disfrutar de la Versión PRO."
                                    } else {
                                        restoreAlertTitle = "Sin Compras Previas"
                                        restoreAlertMessage = "No se encontraron suscripciones activas asociadas a este ID de Apple."
                                    }
                                    showingRestoreAlert = true
                                }
                            }) {
                                Text("Restaurar compras")
                                    .foregroundStyle(theme.textPrimary)
                            }
                        }
                    } header: {
                        Label("Versión PRO", systemImage: "star.fill")
                            .foregroundStyle(Color.yellow)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .textCase(nil)
                    } footer: {
                        if !PremiumManager.shared.isPro {
                            Text("El tema Glass PRO es exclusivo para usuarios premium.")
                        }
                    }
                    .listRowBackground(theme.chipFill)
                    
                    Section {
                        Button(action: { 
                            if PremiumManager.shared.isPro {
                                backupManager.performBackup(from: store) { success in
                                    if success {
                                        backupAlertTitle = "Copia Guardada"
                                        backupAlertMessage = "Tus datos se han guardado correctamente en iCloud."
                                    } else {
                                        backupAlertTitle = "Error"
                                        backupAlertMessage = backupManager.backupError ?? "Hubo un error al guardar los datos."
                                    }
                                    showingBackupAlert = true
                                }
                            } else {
                                showingPaywall = true
                            }
                        }) {
                            HStack {
                                Label("Guardar copia en iCloud", systemImage: "arrow.up.doc.fill")
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                if !PremiumManager.shared.isPro {
                                    Image(systemName: "lock.fill").foregroundStyle(Color.gray)
                                } else if backupManager.isBackingUp {
                                    ProgressView()
                                } else {
                                    Image(systemName: "cloud.fill").foregroundStyle(.cyan)
                                }
                            }
                        }
                        .disabled(backupManager.isBackingUp || backupManager.isRestoring)
                        
                        Button(action: { 
                            if PremiumManager.shared.isPro {
                                backupManager.performRestore(to: store) { success in
                                    if success {
                                        backupAlertTitle = "Datos Restaurados"
                                        backupAlertMessage = "Tus datos se han recuperado correctamente desde iCloud."
                                    } else {
                                        backupAlertTitle = "Error"
                                        backupAlertMessage = backupManager.backupError ?? "No se pudo restaurar la copia de iCloud."
                                    }
                                    showingBackupAlert = true
                                }
                            } else {
                                showingPaywall = true
                            }
                        }) {
                            HStack {
                                Label("Restaurar desde iCloud", systemImage: "arrow.down.doc.fill")
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                if !PremiumManager.shared.isPro {
                                    Image(systemName: "lock.fill").foregroundStyle(Color.gray)
                                } else if backupManager.isRestoring {
                                    ProgressView()
                                } else {
                                    Image(systemName: "cloud.fill").foregroundStyle(.cyan)
                                }
                            }
                        }
                        .disabled(backupManager.isBackingUp || backupManager.isRestoring)
                        
                        if let error = backupManager.backupError {
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        } else if let date = backupManager.lastBackupDate, PremiumManager.shared.isPro {
                            Text("Última copia: \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(theme.textMuted)
                        }
                    } header: {
                        Label("Copia en la Nube", systemImage: "icloud.fill")
                            .foregroundStyle(Color.cyan)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .textCase(nil)
                    } footer: {
                        Text("Guarda y restaura tus datos en iCloud (Exclusivo PRO).")
                    }
                    .listRowBackground(theme.chipFill)

                    Section {
                        Toggle(isOn: $showHealthTips) {
                            Label("Mostrar consejos de salud", systemImage: "leaf.fill")
                                .foregroundStyle(theme.textPrimary)
                        }
                        .tint(theme.accent)
                        
                        Toggle(isOn: Binding(
                            get: { PremiumManager.shared.isPro ? showGamification : false },
                            set: { newValue in
                                if PremiumManager.shared.isPro {
                                    showGamification = newValue
                                } else {
                                    showingPaywall = true
                                }
                            }
                        )) {
                            HStack {
                                Label("Mostrar rachas y estadísticas", systemImage: "flame.fill")
                                    .foregroundStyle(theme.textPrimary)
                                if !PremiumManager.shared.isPro {
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(Color.gray)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .tint(theme.accent)
                    } header: {
                        Label("Experiencia", systemImage: "gamecontroller.fill")
                            .foregroundStyle(theme.textSecondary)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .textCase(nil)
                    } footer: {
                        Text("Activa los consejos de salud o las rachas e historial para personalizar tu pantalla de inicio.")
                    }
                    .listRowBackground(theme.chipFill)

                    Section {
                        Toggle(isOn: $requireFaceID) {
                            Label("Requerir Face ID", systemImage: "faceid")
                                .foregroundStyle(theme.textPrimary)
                        }
                        .tint(theme.accent)
                    } header: {
                        Label("Seguridad", systemImage: "lock.fill")
                            .foregroundStyle(theme.textSecondary)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .textCase(nil)
                    } footer: {
                        Text("Bloquea la aplicación y oculta la información al minimizarla.")
                    }
                    .listRowBackground(theme.chipFill)

                    Section {
                        NavigationLink(destination: NotificationSettingsView(store: store).environment(\.appTheme, theme)) {
                            Label("Notificaciones", systemImage: "bell.badge.fill")
                                .foregroundStyle(theme.textPrimary)
                        }
                    } header: {
                        Label("Avisos", systemImage: "bell.fill")
                            .foregroundStyle(theme.textSecondary)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .textCase(nil)
                    }
                    .listRowBackground(theme.chipFill)
                    
                    Section {
                        Toggle(isOn: $hapticFeedbackEnabled) {
                            Label("Vibración y Háptica", systemImage: "hand.tap.fill")
                                .foregroundStyle(theme.textPrimary)
                        }
                        .tint(theme.accent)
                        .onChange(of: hapticFeedbackEnabled) { _, newValue in
                            if newValue {
                                HapticManager.shared.notification(type: .success)
                            }
                        }
                    } header: {
                        Label("Accesibilidad", systemImage: "figure.walk.circle.fill")
                        .foregroundStyle(theme.textSecondary)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .textCase(nil)
                    }
                    .listRowBackground(theme.chipFill)
                    
                    Section(header: Label("Informe Médico", systemImage: "doc.text.fill").foregroundStyle(theme.textSecondary).font(.system(.subheadline, design: .rounded).weight(.semibold)).textCase(nil)) {
                        Button(action: { generatePDF() }) {
                            HStack {
                                Label("Generar Informe Médico (PDF)", systemImage: "doc.text.fill")
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                if !PremiumManager.shared.isPro {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 10))
                                        Text("PRO")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange))
                                } else if isGeneratingPDF {
                                    ProgressView()
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(theme.accent)
                                }
                            }
                        }
                        .disabled(isGeneratingPDF)
                    }
                    .listRowBackground(theme.chipFill)
                    
                    Section(header: Label("Soporte y Feedback", systemImage: "questionmark.circle.fill").foregroundStyle(theme.textSecondary).font(.system(.subheadline, design: .rounded).weight(.semibold)).textCase(nil)) {
                        Button(action: {
                            if let url = URL(string: "https://apps.apple.com/app/id6789236725?action=write-review") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Label("Valorar en la App Store", systemImage: "star")
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(theme.textSecondary.opacity(0.5))
                            }
                        }
                        
                        Button(action: {
                            if let url = URL(string: "mailto:soporte@jmrsoft.com?subject=Sugerencia%20para%20la%20app") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Label("Sugerir una Mejora", systemImage: "lightbulb")
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(theme.textSecondary.opacity(0.5))
                            }
                        }
                        
                        Button(action: {
                            if let url = URL(string: "mailto:soporte@jmrsoft.com?subject=Fallo%20o%20Bug%20en%20la%20app") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Label("Reportar un Error", systemImage: "ant")
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(theme.textSecondary.opacity(0.5))
                            }
                        }
                    }
                    .listRowBackground(theme.chipFill)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ajustes")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundStyle(theme.accent)
                }
            }
        .alert(backupAlertTitle, isPresented: $showingBackupAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(backupAlertMessage)
        }
        .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .preferredColorScheme(activeColorScheme)
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(activityItems: [url])
                        .presentationDetents([.medium, .large])
                }
            }
            .alert(restoreAlertTitle, isPresented: $showingRestoreAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(restoreAlertMessage)
            }
        }
    }

    private func generatePDF() {
        if !PremiumManager.shared.isPro {
            showingPaywall = true
            return
        }
        
        isGeneratingPDF = true
        // Simulamos un pequeñísimo retardo para la animación del ProgressView
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            let url = PDFGenerator.generateMedicalReport(store: store, isAdvanced: true)
            self.pdfURL = url
            self.isGeneratingPDF = false
            if url != nil {
                self.showShareSheet = true
            }
        }
    }
}

#Preview {
    AppSettingsView(store: MedicationStore())
}
