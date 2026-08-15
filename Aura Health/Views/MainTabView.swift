//
//  MainTabView.swift
//  Aura Health
//

import SwiftUI

enum AppTab: Int, CaseIterable {
    case home = 0
    case medication = 1
    case appointments = 2
}

struct MainTabView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appUIStyle") private var appUIStyle: String = "classic"
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @State private var store = MedicationStore()
    @State private var selectedTab: AppTab = .home
    @State private var showSettings = false

    private var isDark: Bool { appUIStyle == "proGlass" && appThemeMode == "pureBlack" }
    private var isGraphite: Bool { appUIStyle == "proGlass" && appThemeMode == "graphite" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)
    @State private var showAddMenu = false
    
    @AppStorage("appLaunchCount") private var appLaunchCount: Int = 0
    @AppStorage("lastSoftPaywallDate") private var lastSoftPaywallDate: Double = 0
    @State private var showingSoftPaywall = false
    
    private var activeColorScheme: ColorScheme? {
        switch appThemeMode {
        case "pureBlack", "blueDark", "graphite": return .dark
        case "light": return .light
        default: return colorScheme == .dark ? .dark : .light
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Group {
                        switch selectedTab {
                        case .home:
                            if appUIStyle == "proGlass" {
                                ProGlassHomeView(store: store, showSettings: $showSettings, onAddTap: { showAddMenu = true })
                            } else {
                                HomeView(store: store, showSettings: $showSettings, onAddTap: { showAddMenu = true })
                            }
                        case .medication:
                            if appUIStyle == "proGlass" {
                                ProGlassMedicationListView(store: store)
                            } else {
                                MedicationListView(store: store)
                            }
                        case .appointments:
                            if appUIStyle == "proGlass" {
                                ProGlassAppointmentsListView(store: store)
                            } else {
                                AppointmentsListView(store: store)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if selectedTab != .home {
                        homeBackButton
                    }
                }

                if appUIStyle != "proGlass" {
                    bottomBar
                }
            }
            
            if appUIStyle == "proGlass" {
                VStack {
                    Spacer()
                    bottomBar
                }
            }
        }
        .sheet(isPresented: $showAddMenu) {
            if appUIStyle == "proGlass" {
                ProGlassAddMenuSheet(store: store)
                    .presentationDetents([.medium])
                    .environment(\.appTheme, theme)
                    .applyThemeMode()
            } else {
                AddMenuSheet(store: store)
                    .presentationDetents([.medium])
                    .environment(\.appTheme, theme)
                    .applyThemeMode()
            }
        }
        .background {
            if appUIStyle == "proGlass" {
                if isGraphite {
                    Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
                } else {
                    (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                }
            } else {
                OptimalBackground()
            }
        }
        .sheet(isPresented: $showSettings) {
            if appUIStyle == "proGlass" {
                ProGlassAppSettingsView(store: store)
                    .environment(\.appTheme, theme)
                    .applyThemeMode()
            } else {
                AppSettingsView(store: store)
                    .environment(\.appTheme, theme)
                    .applyThemeMode()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.resetIfNewDay()
            }
        }
        .onAppear {
            // Start background services (WatchSync) after the UI has appeared
            store.startBackgroundServices()
            
            appLaunchCount += 1
            
            if !PremiumManager.shared.isPro && appLaunchCount >= 10 {
                let now = Date().timeIntervalSince1970
                let sixDaysInSeconds: Double = 6 * 24 * 60 * 60
                
                if (now - lastSoftPaywallDate) >= sixDaysInSeconds {
                    // Reiniciar contadores para el próximo ciclo
                    appLaunchCount = 0
                    lastSoftPaywallDate = now
                    
                    // Pequeño retraso para que no sea tan brusco
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showingSoftPaywall = true
                    }
                }
            }
            
            // Enforce PRO lock on startup
            if appUIStyle == "proGlass" && !PremiumManager.shared.isPro {
                appUIStyle = "classic"
            }
        }
    }

    private var bottomBar: some View {
        Group {
            if appUIStyle == "proGlass" {
                ZStack {
                    HStack {
                        tabButton(tab: .medication, icon: "pills.fill", label: "Mi Medicación")
                        Spacer(minLength: 0)
                        addButton
                        Spacer(minLength: 0)
                        tabButton(tab: .appointments, icon: "calendar.badge.clock", label: "Mis Citas")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 15, y: 5)
                    )
                    .padding(.horizontal, 30)
                    .padding(.bottom, 0)
                }
            } else {
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        HStack {
                            tabButton(
                                tab: .medication,
                                icon: "pills.fill",
                                label: "Mi Medicación"
                            )

                            Spacer(minLength: 0)

                            tabButton(
                                tab: .appointments,
                                icon: "calendar.badge.clock",
                                label: "Mis Citas"
                            )
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 14)
                        .padding(.bottom, 10)
                    }

                    addButton
                        .offset(y: 14)
                }
                .background(
                    ZStack(alignment: .top) {
                        theme.barFill
                            .shadow(color: theme.softShadow, radius: 16, y: -6)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.trackGray.opacity(0.25),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 1)
                    }
                    .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }

    private var addButton: some View {
        Button {
            showAddMenu = true
        } label: {
            ZStack {
                if appUIStyle == "proGlass" {
                    // Glass PRO squircle button
                    ZStack {
                        // Base gradient fill
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: isGraphite
                                        ? [gold, Color(red: 0.72, green: 0.53, blue: 0.2)]
                                        : isDark
                                        ? [Color.green.opacity(0.75), Color.mint.opacity(0.85)]
                                        : [Color.blue.opacity(0.75), Color.purple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Frosted glass inner shine
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Glowing border
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isGraphite ? 0.5 : 0.7),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )

                        // Icon
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(isGraphite ? Color.black.opacity(0.7) : .white)
                    }
                    .frame(width: 66, height: 66)
                    .shadow(color: isGraphite ? gold.opacity(0.5) : isDark ? Color.green.opacity(0.5) : Color.blue.opacity(0.4), radius: isGraphite ? 12 : isDark ? 14 : 10, y: 5)
                    .shadow(color: isGraphite ? gold.opacity(0.2) : isDark ? Color.mint.opacity(0.25) : Color.purple.opacity(0.2), radius: 4, y: 2)

                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.accent.opacity(0.85),
                                    theme.accent
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: theme.accent.opacity(0.4), radius: 8, y: 4)

                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 2)
                        .frame(width: 64, height: 64)

                    Image(systemName: "plus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }


    private var homeBackButton: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedTab = .home
                }
            } label: {
                if appUIStyle == "proGlass" {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("Inicio")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        isGraphite
                        ? LinearGradient(colors: [gold, Color(red: 0.72, green: 0.53, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : isDark
                        ? LinearGradient(colors: [Color.green.opacity(0.85), Color.mint.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Capsule(style: .continuous))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(LinearGradient(colors: [Color.white, Color.white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                    )
                    .shadow(color: isGraphite ? gold.opacity(0.4) : isDark ? Color.green.opacity(0.35) : Color.purple.opacity(0.3), radius: 10, y: 4)
                } else {
                    Label("Inicio", systemImage: "house.fill")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.chipFill)
                                .shadow(color: theme.softShadow, radius: 4, y: 2)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func tabButton(tab: AppTab, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if isSelected {
                        if appUIStyle == "proGlass" {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 68, height: 44)
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(theme.accent.opacity(0.12))
                                .frame(width: 68, height: 44)
                                .shadow(color: theme.accent.opacity(0.1), radius: 4, y: 2)
                        }
                    }

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: isSelected ? .semibold : .regular))
                }
                .frame(height: 44)

                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? (appUIStyle == "proGlass" ? Color.blue : theme.accent) : (appUIStyle == "proGlass" ? Color.gray : theme.textMuted))
            .frame(width: 100)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
