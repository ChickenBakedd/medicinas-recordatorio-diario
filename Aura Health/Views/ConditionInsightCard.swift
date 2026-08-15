import SwiftUI

struct ConditionInsightCard: View {
    @Bindable var store: MedicationStore
    @AppStorage("appUIStyle") private var appUIStyle: String = "classic"
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @Environment(\.appTheme) private var theme
    
    private var isGraphite: Bool { appUIStyle == "proGlass" && appThemeMode == "graphite" }
    
    private var activeProfile: UserProfile? {
        store.profiles.first(where: { $0.id == store.activeProfileId })
    }
    
    private var insight: (title: String, description: String, icon: String, color: Color)? {
        guard let condition = activeProfile?.medicalConditions.first else { return nil }
        
        switch condition {
        case "Asma":
            return ("Alerta de Polen", "Revisa tus inhaladores. Los niveles de polen están altos esta semana.", "wind", .blue)
        case "Diabetes":
            return ("Rotación de Zonas", "Recuerda rotar las zonas de inyección de insulina para evitar lipodistrofia.", "drop.fill", .red)
        case "Hipertensión":
            return ("Control de Sal", "Evita los alimentos procesados y mantén bajo tu consumo de sodio hoy.", "heart.text.square", .orange)
        case "VIH":
            return ("Adherencia Clave", "Mantén la toma de medicación siempre a la misma hora para evitar resistencias.", "shield.lefthalf.filled", .purple)
        case "TDAH":
            return ("Rutina Estable", "Intenta asociar la toma de tu medicación con un hábito diario (ej. cepillarte los dientes).", "brain.head.profile", .teal)
        case "Enfermedad Cardíaca":
            return ("Actividad Moderada", "Mantén actividad física suave como caminar 30 minutos al día, sin forzar.", "figure.walk.heart", .pink)
        case "Colesterol Alto":
            return ("Alimentación", "Aumenta el consumo de omega-3 y evita grasas saturadas en la cena.", "leaf.fill", .green)
        default:
            return nil
        }
    }
    
    var body: some View {
        if let insight = insight {
            if appUIStyle == "proGlass" {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(insight.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: insight.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(insight.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(isGraphite ? .white.opacity(0.9) : .primary.opacity(0.9))
                        Text(insight.description)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(isGraphite ? .white.opacity(0.6) : .secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(16)
                .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(insight.color.opacity(isGraphite ? 0.3 : 0.2), lineWidth: 1)
                )
                .padding(.horizontal, 24)
            } else {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(insight.color.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: insight.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(insight.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(theme.textPrimary)
                        Text(insight.description)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(16)
                .background(theme.chipFill)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: theme.softShadow, radius: 4, y: 2)
                .padding(.horizontal, 20)
            }
        }
    }
}
