//
//  ProGlassAppSettingsView.swift
//  Aura Health
//

import SwiftUI
import WidgetKit

struct ProGlassAppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @AppStorage("widgetThemeMode", store: UserDefaults(suiteName: "group.com.jmrsoft.medicinas")) private var widgetThemeMode: String = "sync"
    @AppStorage("appUIStyle") private var appUIStyle: String = "classic"
    @AppStorage("requireFaceID") private var requireFaceID: Bool = false
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("showGamification") private var showGamification: Bool = false
    @AppStorage("showHealthTips") private var showHealthTips: Bool = true

    @State private var showingPaywall = false
    @Bindable var store: MedicationStore
    @ObservedObject private var backupManager = CloudBackupManager.shared
    
    private var uiStyleBinding: Binding<String> {
        Binding(
            get: { appUIStyle },
            set: { newValue in
                if newValue == "classic" {
                    appUIStyle = newValue
                    if appThemeMode == "graphite" {
                        appThemeMode = "system"
                        UserDefaults(suiteName: "group.com.jmrsoft.medicinas")?.set("system", forKey: "appThemeMode")
                    }
                } else if newValue == "proGlass" && !PremiumManager.shared.isPro {
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

    private var isDark: Bool { appThemeMode == "pureBlack" }
    private var isGraphite: Bool { appThemeMode == "graphite" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)

    private var activeColorScheme: ColorScheme? {
        if appThemeMode == "light" { return .light }
        if appThemeMode == "pureBlack" { return .dark }
        if appThemeMode == "graphite" { return .dark }
        return nil
    }

    private var labelColor: Color {
        (isDark || isGraphite) ? Color.white.opacity(0.85) : Color.black.opacity(0.8)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                glassBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        

                        // Versión PRO
                        glassSection(title: "Versión PRO", icon: "star.fill", iconColor: .yellow, footer: "Activa la nueva interfaz premium y descubre un diseño cristalino exclusivo.") {
                            VStack(spacing: 12) {
                                Picker("Interfaz de la App", selection: uiStyleBinding) {
                                    Text("Clásica (Gratis)").tag("classic")
                                    Text("Glass PRO ✨").tag("proGlass")
                                }
                                .pickerStyle(.segmented)
                                
                                if appUIStyle == "proGlass" {
                                    Divider().background(isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.3))
                                    
                                    Picker("Modo de Color", selection: $appThemeMode) {
                                        Text("Light Glass").tag("light")
                                        Text("Dark Glass").tag("pureBlack")
                                        Text("Graphite ◆ Gold").tag("graphite")
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: appThemeMode) { _, newValue in
                                        UserDefaults(suiteName: "group.com.jmrsoft.medicinas")?.set(newValue, forKey: "appThemeMode")
                                        WidgetCenter.shared.reloadAllTimelines()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Widgets PRO
                        if appUIStyle == "proGlass" {
                            glassSection(title: "Widgets", icon: "square.dashed.inset.filled", iconColor: .blue, footer: "Personaliza el aspecto de tus widgets en la pantalla de inicio.") {
                                VStack(spacing: 12) {
                                    Picker("Tema del Widget", selection: $widgetThemeMode) {
                                        Text("Sincronizar").tag("sync")
                                        Text("Claro").tag("light")
                                        Text("Oscuro").tag("dark")
                                        Text("Grafito").tag("graphite")
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: widgetThemeMode) { _, _ in
                                        WidgetCenter.shared.reloadAllTimelines()
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Familia
                        glassSection(title: "Familia", icon: "person.2.fill", footer: "Gestiona hasta 2 perfiles en la versión gratuita o perfiles ilimitados con la versión PRO.") {
                            NavigationLink(destination: ProGlassProfilesSettingsView(store: store)) {
                                HStack {
                                    Label("Perfiles Familiares", systemImage: "house.fill")
                                        .foregroundStyle(labelColor)
                                    Spacer()
                                    if !PremiumManager.shared.isPro {
                                        Text("\(store.profiles.count)/2 gratis")
                                            .font(.system(.caption, design: .rounded).weight(.medium))
                                            .foregroundStyle(Color.gray)
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
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.gray.opacity(0.5))
                                }
                            }
                        }

                        // Seguridad
                        glassSection(title: "Seguridad", icon: "lock.fill", footer: "Bloquea la aplicación y oculta la información al minimizarla.") {
                            Toggle(isOn: $requireFaceID) {
                                Label("Requerir Face ID", systemImage: "faceid")
                                    .foregroundStyle(labelColor)
                            }
                            .tint(.blue)
                        }

                        // Avisos
                        glassSection(title: "Avisos", icon: "bell.fill") {
                            NavigationLink(destination: ProGlassNotificationSettingsView(store: store)) {
                                HStack {
                                    Label("Notificaciones", systemImage: "bell.badge.fill")
                                        .foregroundStyle(labelColor)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.gray.opacity(0.5))
                                }
                            }
                        }

                        // Experiencia
                        glassSection(title: "Experiencia", icon: "gamecontroller.fill", footer: "Activa los consejos de salud o las rachas e historial para personalizar tu pantalla de inicio.") {
                            VStack(spacing: 16) {
                                Toggle(isOn: $showHealthTips) {
                                    Label("Mostrar consejos de salud", systemImage: "leaf.fill")
                                        .foregroundStyle(labelColor)
                                }
                                .tint(.blue)
                                
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
                                            .foregroundStyle(labelColor)
                                        if !PremiumManager.shared.isPro {
                                            Spacer()
                                            Image(systemName: "lock.fill")
                                                .foregroundStyle(Color.gray)
                                                .font(.system(size: 14))
                                        }
                                    }
                                }
                                .tint(.blue)
                            }
                        }
                        
                        // Accesibilidad
                        glassSection(title: "Accesibilidad", icon: "figure.walk.circle.fill") {
                            Toggle(isOn: $hapticFeedbackEnabled) {
                                Label("Vibración y Háptica", systemImage: "hand.tap.fill")
                                    .foregroundStyle(labelColor)
                            }
                            .tint(.blue)
                            .onChange(of: hapticFeedbackEnabled) { oldValue, newValue in
                                if newValue {
                                    HapticManager.shared.notification(type: .success)
                                }
                            }
                        }
                        
                        // Copia de Seguridad (iCloud)
                        glassSection(title: "Copia en la Nube", icon: "icloud.fill", iconColor: .cyan, footer: "Guarda y restaura tus datos en iCloud (Exclusivo PRO).") {
                            VStack(alignment: .leading, spacing: 12) {
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
                                            .foregroundStyle(labelColor)
                                        Spacer()
                                        if !PremiumManager.shared.isPro {
                                            Image(systemName: "lock.fill").foregroundStyle(isGraphite ? gold : Color.gray)
                                        } else if backupManager.isBackingUp {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "cloud.fill").foregroundStyle(.cyan)
                                        }
                                    }
                                }
                                .disabled(backupManager.isBackingUp || backupManager.isRestoring)
                                
                                Divider().background(isGraphite ? Color.white.opacity(0.1) : Color.gray.opacity(0.2))
                                
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
                                            .foregroundStyle(labelColor)
                                        Spacer()
                                        if !PremiumManager.shared.isPro {
                                            Image(systemName: "lock.fill").foregroundStyle(isGraphite ? gold : Color.gray)
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
                                        .padding(.top, 4)
                                } else if let date = backupManager.lastBackupDate, PremiumManager.shared.isPro {
                                    Text("Última copia: \(date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundStyle(theme.textMuted)
                                    .padding(.top, 4)
                                }
                            }
                        }

                        // Datos
                        glassSection(title: "Informe Médico", icon: "doc.text.fill", iconColor: .blue) {
                            VStack(spacing: 16) {
                                Button(action: { generatePDF() }) {
                                    HStack {
                                        Label("Generar Informe Médico (PDF)", systemImage: "doc.text.fill")
                                            .foregroundStyle(labelColor)
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
                                                .foregroundStyle(Color.blue)
                                        }
                                    }
                                }
                                .disabled(isGeneratingPDF)
                            }
                        }
                        
                        glassSection(title: "Soporte y Feedback", icon: "questionmark.circle.fill", iconColor: .teal) {
                            VStack(spacing: 16) {
                                Button(action: {
                                    if let url = URL(string: "https://apps.apple.com/app/id6789236725?action=write-review") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Label("Valorar en la App Store", systemImage: "star")
                                            .foregroundStyle(labelColor)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(isDark ? Color.white.opacity(0.3) : Color.gray.opacity(0.4))
                                    }
                                }
                                
                                Divider().background(isGraphite ? Color.white.opacity(0.1) : Color.gray.opacity(0.2))
                                
                                Button(action: {
                                    if let url = URL(string: "mailto:soporte@jmrsoft.com?subject=Sugerencia%20para%20la%20app") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Label("Sugerir una Mejora", systemImage: "lightbulb")
                                            .foregroundStyle(labelColor)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(isDark ? Color.white.opacity(0.3) : Color.gray.opacity(0.4))
                                    }
                                }
                                
                                Divider().background(isGraphite ? Color.white.opacity(0.1) : Color.gray.opacity(0.2))
                                
                                Button(action: {
                                    if let url = URL(string: "mailto:soporte@jmrsoft.com?subject=Fallo%20o%20Bug%20en%20la%20app") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Label("Reportar un Error", systemImage: "ant")
                                            .foregroundStyle(labelColor)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(isDark ? Color.white.opacity(0.3) : Color.gray.opacity(0.4))
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Ajustes PRO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(isDark ? Color.white.opacity(0.4) : Color.gray.opacity(0.6))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
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
                if let pdfURL = pdfURL {
                    ShareSheet(activityItems: [pdfURL])
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }
    
    private var glassBackground: some View {
        ZStack {
            if isGraphite {
                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            } else {
                (isDark ? Color.black : Color.white).ignoresSafeArea()
                Circle()
                    .fill(isDark ? Color.indigo.opacity(0.18) : Color.blue.opacity(0.12))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: -150, y: -200)
                Circle()
                    .fill(isDark ? Color.purple.opacity(0.14) : Color.purple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 150, y: 300)
            }
        }
        .ignoresSafeArea()
    }
    
    private func glassSection<Content: View>(title: String, icon: String, iconColor: Color = .gray, footer: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(iconColor == .gray ? Color.gray : iconColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content()
                    .padding()
            }
            .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : isDark ? AnyShapeStyle(Color.white.opacity(0.06)) : AnyShapeStyle(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(
                isGraphite ? gold.opacity(0.25) : isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.5),
                lineWidth: 1))
            .shadow(color: Color.black.opacity(isGraphite ? 0.5 : isDark ? 0.3 : 0.02), radius: 8, y: 2)
            
            if let footer = footer {
                Text(footer)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle((isDark || isGraphite) ? Color.white.opacity(0.4) : Color.gray)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    private func optionRow(title: String, icon: String, iconColor: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(iconColor)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.blue)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func generatePDF() {
        if !PremiumManager.shared.isPro {
            showingPaywall = true
            return
        }
        
        isGeneratingPDF = true
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
