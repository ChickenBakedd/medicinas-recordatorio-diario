//
//  Aura_HealthApp.swift
//  Aura Health
//

import SwiftUI
import LocalAuthentication
import RevenueCat
import UIKit

@main
struct Aura_HealthApp: App {
    @AppStorage("appThemeMode") private var appThemeMode: String = "light"
    @AppStorage("appUIStyle") private var appUIStyle: String = "classic"
    @AppStorage("requireFaceID") private var requireFaceID: Bool = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var isUnlocked: Bool = false
    @State private var authError: String? = nil

    init() {
        // Initialize RevenueCat completely off the critical path, 
        // after the UI is guaranteed to have rendered.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Purchases.configure(withAPIKey: "appl_bXKwwNKOLWdRmHbdaFOvbOOcvDi")
        }
    }
    
    /// Forces the UIWindow's userInterfaceStyle to match the app's chosen theme.
    /// This is the only reliable way to fix native UIKit-backed SwiftUI components
    /// (Form, List cells, UITextField placeholders) under a non-system color scheme.
    static func applyUIKitInterfaceStyle() {
        // Read directly from UserDefaults (not @AppStorage) since this is a static func
        // Default is "light" matching the app's default theme
        let mode = UserDefaults.standard.string(forKey: "appThemeMode") ?? "light"
        let style: UIUserInterfaceStyle
        switch mode {
        case "pureBlack", "blueDark", "graphite": style = .dark
        case "light": style = .light
        default: style = .unspecified   // "system" → follow the OS
        }
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }
    
    var currentTheme: AppTheme {
        switch appThemeMode {
        case "pureBlack": return .pureBlack
        case "blueDark": return .blueDark
        case "light": return .light
        case "graphite": return .pureBlack  // reuse dark theme as base
        default: return colorScheme == .dark ? .pureBlack : .light
        }
    }
    
    var preferredColorScheme: ColorScheme? {
        switch appThemeMode {
        case "pureBlack", "blueDark", "graphite": return .dark
        case "light": return .light
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Fallback background so no black flash ever appears
                currentTheme.backgroundTop.ignoresSafeArea()
                MainTabView()
                    .applyThemeMode()
                    .environment(\.appTheme, currentTheme)
                    .onAppear {
                        // Apply UIKit-level theme NOW — the window exists at this point
                        Aura_HealthApp.applyUIKitInterfaceStyle()
                        UNUserNotificationCenter.current().delegate = NotificationManager.shared
                        if hasSeenOnboarding {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                NotificationManager.shared.requestPermissions()
                            }
                        }
                    }
                
                if !hasSeenOnboarding {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                        .preferredColorScheme(preferredColorScheme)
                        .environment(\.appTheme, currentTheme)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(2) // Ensure it's above everything including lock screen
                } else if requireFaceID && !isUnlocked {
                    ZStack {
                        if appUIStyle == "proGlass" {
                            if appThemeMode == "graphite" {
                                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
                            } else {
                                (preferredColorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                            }
                        } else {
                            currentTheme.backgroundTop.ignoresSafeArea()
                        }
                        
                        VStack(spacing: 20) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 70))
                                .foregroundStyle(currentTheme.accent)
                            Text("App Bloqueada")
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(currentTheme.textPrimary)
                            Button("Desbloquear") {
                                authenticate()
                            }
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(currentTheme.accent))
                            .shadow(color: currentTheme.accent.opacity(0.4), radius: 8, y: 4)
                            
                            if let errorMsg = authError {
                                Text(errorMsg)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .onChange(of: appThemeMode) { _, _ in
                // Re-apply UIKit style whenever user changes the theme in Settings
                Aura_HealthApp.applyUIKitInterfaceStyle()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    ReviewManager.shared.appOpened()
                    // Re-apply when returning to foreground (e.g. after changing iOS system mode)
                    Aura_HealthApp.applyUIKitInterfaceStyle()
                }
                
                if requireFaceID {
                    if newPhase == .background {
                        isUnlocked = false
                    } else if newPhase == .active && !isUnlocked {
                        authenticate()
                    }
                } else {
                    isUnlocked = true
                }
            }
            .onAppear {
                if !requireFaceID {
                    isUnlocked = true
                } else {
                    authenticate()
                }
            }
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // Use deviceOwnerAuthentication to fallback to passcode if FaceID fails or is unavailable
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Desbloquea Medicinas para ver tus datos médicos") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.isUnlocked = true
                            self.authError = nil
                        }
                    } else {
                        self.authError = "Autenticación fallida. Inténtalo de nuevo."
                    }
                }
            }
        } else {
            // Secure fallback: If the device has no passcode or biometrics, DO NOT unlock.
            // Require the user to set up a passcode in iOS Settings to protect their medical data.
            DispatchQueue.main.async {
                self.authError = "Por seguridad, debes configurar un código o Face ID en los Ajustes de tu iPhone para usar la app."
            }
        }
    }
}
