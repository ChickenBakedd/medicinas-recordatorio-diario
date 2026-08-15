//
//  ProfilesSettingsView.swift
//  Aura Health
//

import SwiftUI

struct ProfilesSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Bindable var store: MedicationStore
    
    @State private var showingAddProfile = false
    @State private var newProfileName: String = ""
    @State private var newProfileColor: String = "blue"
    @State private var newProfileConditions: Set<String> = []
    @State private var showingPaywall = false
    
    @AppStorage("appUIStyle") private var appUIStyle: String = "classic"
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @Environment(\.colorScheme) private var colorScheme
    
    private var isGraphite: Bool { appUIStyle == "proGlass" && appThemeMode == "graphite" }
    private var isDark: Bool { appUIStyle == "proGlass" && appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)
    
    let colors = ["blue", "purple", "green", "orange", "red", "pink", "teal"]
    let conditionsList = ["Asma", "Diabetes", "TDAH", "Hipertensión", "VIH", "Enfermedad Cardíaca", "Colesterol Alto"]
    
    var body: some View {
        ZStack {
            if appUIStyle == "proGlass" {
                glassBackground
            } else {
                OptimalBackground()
            }
            List {
                Section {
                    ForEach(store.profiles) { profile in
                        HStack {
                            Circle()
                                .fill(colorFromString(profile.avatarColor))
                                .frame(width: 30, height: 30)
                                .overlay(Text(profile.name.prefix(1)).font(.caption).bold().foregroundStyle(.white))
                            
                            Text(profile.name)
                                .foregroundStyle(theme.textPrimary)
                            
                            Spacer()
                            
                            if profile.isMain {
                                Text("Principal")
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(theme.trackGray))
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !profile.isMain {
                                Button(role: .destructive) {
                                    store.deleteProfile(id: profile.id)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Tus Perfiles (\(store.profiles.count)/\(PremiumManager.shared.isPro ? "∞" : "2"))")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Desliza a la izquierda para eliminar un perfil. El perfil principal no se puede borrar.")
                        if !PremiumManager.shared.isPro {
                            Text("Versión gratuita: hasta 2 perfiles. Desbloquea la versión PRO para perfiles ilimitados.")
                                .foregroundStyle(Color.orange)
                        }
                    }
                    .foregroundStyle(appUIStyle == "proGlass" ? Color.gray : theme.textSecondary)
                }
                .listRowBackground(appUIStyle == "proGlass" ? (isGraphite ? Color.white.opacity(0.05) : Color.black.opacity(0.1)) : theme.chipFill)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Perfiles Familiares")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if store.profiles.count >= 2 && !PremiumManager.shared.isPro {
                        showingPaywall = true
                    } else {
                        showingAddProfile = true
                    }
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .applyThemeMode()
        }
        .sheet(isPresented: $showingAddProfile) {
            NavigationStack {
                ZStack {
                    OptimalBackground()
                    Form {
                        Section {
                            TextField("Nombre del perfil", text: $newProfileName)
                        }
                        
                        Section("Color del Perfil") {
                            HStack {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(colorFromString(color))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: newProfileColor == color ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            newProfileColor = color
                                        }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Section("Condiciones Médicas (Opcional)") {
                            ForEach(conditionsList, id: \.self) { condition in
                                Button(action: {
                                    if newProfileConditions.contains(condition) {
                                        newProfileConditions.remove(condition)
                                    } else {
                                        newProfileConditions.insert(condition)
                                    }
                                }) {
                                    HStack {
                                        Text(condition)
                                            .foregroundColor(theme.textPrimary)
                                        Spacer()
                                        if newProfileConditions.contains(condition) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("Nuevo Perfil")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showingAddProfile = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            let profile = UserProfile(name: newProfileName, avatarColor: newProfileColor, isMain: false, medicalConditions: Array(newProfileConditions))
                            store.addProfile(profile)
                            showingAddProfile = false
                            newProfileName = ""
                            newProfileConditions = []
                        }
                        .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .applyThemeMode()
        }
    }
    
    private func colorFromString(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "teal": return .teal
        default: return .gray
        }
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
