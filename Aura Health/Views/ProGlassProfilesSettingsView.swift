import SwiftUI

struct ProGlassProfilesSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var store: MedicationStore
    
    @State private var showingAddProfile = false
    @State private var showingPaywall = false
    
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
                    ForEach(store.profiles) { profile in
                        HStack {
                            Circle()
                                .fill(colorFromString(profile.avatarColor))
                                .frame(width: 30, height: 30)
                                .overlay(Text(profile.name.prefix(1)).font(.caption).bold().foregroundStyle(.white))
                            
                            Text(profile.name)
                                .foregroundStyle(isGraphite ? .white : .primary)
                            
                            Spacer()
                            
                            if profile.isMain {
                                Text("Principal")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(tint.opacity(0.8)))
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
                    .foregroundStyle(Color.gray)
                }
                .listRowBackground(isGraphite ? Color.white.opacity(0.05) : Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.7))
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
                        .foregroundStyle(tint)
                }
            }
        }
        .sheet(isPresented: $showingAddProfile) {
            ProGlassAddProfileSheet(store: store)
                .applyThemeMode()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
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

struct ProGlassAddProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var store: MedicationStore
    
    @State private var newProfileName: String = ""
    @State private var newProfileColor: String = "blue"
    @State private var newProfileConditions: Set<String> = []
    @State private var showingPaywall = false
    
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    
    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)
    
    private var tint: Color {
        isGraphite ? gold : isDark ? Color.green : Color.blue
    }
    
    let colors = ["blue", "purple", "green", "orange", "red", "pink", "teal"]
    let conditionsList = ["Asma", "Diabetes", "TDAH", "Hipertensión", "VIH", "Enfermedad Cardíaca", "Colesterol Alto"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                glassBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Text Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre del perfil")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            TextField("Escribe el nombre...", text: $newProfileName)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(isGraphite ? Color.white.opacity(0.05) : Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.7))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .foregroundColor(isGraphite ? .white : .primary)
                        }
                        
                        // Color
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color del perfil")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(colorFromString(color))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(tint, lineWidth: newProfileColor == color ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            newProfileColor = color
                                        }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Conditions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Condiciones Médicas (Opcional)")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 12) {
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
                                                .foregroundColor(isGraphite ? .white : .primary)
                                            Spacer()
                                            if newProfileConditions.contains(condition) {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(tint)
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(isGraphite ? Color.white.opacity(0.05) : Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.7))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Nuevo Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(isGraphite ? .white : .primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let profile = UserProfile(name: newProfileName, avatarColor: newProfileColor, isMain: false, medicalConditions: Array(newProfileConditions))
                        store.addProfile(profile)
                        dismiss()
                    }
                    .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : tint)
                    .fontWeight(.bold)
                }
            }
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
