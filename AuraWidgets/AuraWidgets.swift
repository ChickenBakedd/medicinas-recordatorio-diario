import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MedicationEntry {
        MedicationEntry(date: Date(), upcomingDoses: [], activeTheme: "light")
    }

    func getSnapshot(in context: Context, completion: @escaping (MedicationEntry) -> ()) {
        let store = MedicationStore()
        let pending = store.allDoses.filter { !$0.isTaken }.sorted(by: { $0.scheduledTime < $1.scheduledTime })
        let upcoming = Array(pending.prefix(4))
        let appThemeMode = UserDefaults(suiteName: "group.com.jmrsoft.medicinas")?.string(forKey: "appThemeMode") ?? "light"
        let widgetThemeMode = UserDefaults(suiteName: "group.com.jmrsoft.medicinas")?.string(forKey: "widgetThemeMode") ?? "sync"
        let activeTheme = widgetThemeMode == "sync" ? appThemeMode : widgetThemeMode
        
        let entry = MedicationEntry(date: Date(), upcomingDoses: upcoming, activeTheme: activeTheme)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let store = MedicationStore()
        let pending = store.allDoses.filter { !$0.isTaken }.sorted(by: { $0.scheduledTime < $1.scheduledTime })
        let upcoming = Array(pending.prefix(4))
        
        let appThemeMode = UserDefaults(suiteName: "group.com.jmrsoft.medicinas")?.string(forKey: "appThemeMode") ?? "light"
        let widgetThemeMode = UserDefaults(suiteName: "group.com.jmrsoft.medicinas")?.string(forKey: "widgetThemeMode") ?? "sync"
        let activeTheme = widgetThemeMode == "sync" ? appThemeMode : widgetThemeMode
        
        let entry = MedicationEntry(date: Date(), upcomingDoses: upcoming, activeTheme: activeTheme)
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

struct MedicationEntry: TimelineEntry {
    let date: Date
    let upcomingDoses: [MedicationDose]
    let activeTheme: String
}

struct AuraWidgetsBackground: View {
    var activeTheme: String
    
    var isGraphite: Bool {
        return activeTheme == "graphite"
    }
    var isDark: Bool {
        return activeTheme == "pureBlack" || activeTheme == "dark" || isGraphite
    }
    
    var body: some View {
        if isGraphite {
            Color(red: 0.18, green: 0.18, blue: 0.20)
        } else if isDark {
            Color.black
        } else {
            LinearGradient(colors: [Color.white, Color(red: 0.95, green: 0.96, blue: 0.99)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Componentes de UI
struct WidgetHeaderView: View {
    var isDark: Bool
    var isGraphite: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "pill.fill")
                .foregroundStyle(isGraphite ? AnyShapeStyle(Color.yellow.gradient) : (isDark ? AnyShapeStyle(Color.indigo) : AnyShapeStyle(Color.blue)))
                .font(.system(size: 14))
            Text("Medicinas")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isDark ? Color.white.opacity(0.8) : Color.gray)
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

struct EmptyStateView: View {
    var isDark: Bool
    var isSmall: Bool = true
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: isSmall ? 32 : 44))
                .foregroundStyle(Color.green.gradient)
            
            Text("¡Todo al día!")
                .font(.system(size: isSmall ? 14 : 18, weight: .semibold, design: .rounded))
                .foregroundStyle(isDark ? Color.white : Color.black)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DoseRowView: View {
    let dose: MedicationDose
    let isDark: Bool
    let showDivider: Bool
    var isGraphite: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dose.medicationName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(isDark ? Color.white : Color.black)
                        .lineLimit(1)
                    
                    Text("\(dose.doseDescription) • \(dose.scheduledTime, style: .time)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(isDark ? Color.white.opacity(0.6) : Color.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if #available(iOS 17.0, *) {
                    Button(intent: TakeMedicationIntent(doseId: dose.id.uuidString)) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(isGraphite ? Color.yellow.gradient : Color.green.gradient))
                    }
                    .buttonStyle(.plain)
                }
            }
            if showDivider {
                Divider().opacity(isDark ? 0.3 : 0.5)
            }
        }
    }
}

// MARK: - Vistas por Tamaño
struct SmallMedicationView: View {
    let dose: MedicationDose
    let isDark: Bool
    var isGraphite: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeaderView(isDark: isDark, isGraphite: isGraphite)
            
            Spacer(minLength: 0)
            
            Text(dose.medicationName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(isDark ? Color.white : Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(dose.doseDescription)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(isDark ? Color.white.opacity(0.6) : Color.gray)
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Próxima")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(isDark ? Color.white.opacity(0.5) : Color.gray)
                    Text(dose.scheduledTime, style: .time)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(isDark ? Color.white : Color.black)
                }
                
                Spacer()
                
                if #available(iOS 17.0, *) {
                    Button(intent: TakeMedicationIntent(doseId: dose.id.uuidString)) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(isGraphite ? Color.yellow.gradient : Color.green.gradient))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct MediumWidgetView: View {
    var doses: [MedicationDose]
    var isDark: Bool
    var isGraphite: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeaderView(isDark: isDark, isGraphite: isGraphite)
            
            VStack(spacing: 8) {
                ForEach(Array(doses.prefix(2).enumerated()), id: \.element.id) { index, dose in
                    DoseRowView(dose: dose, isDark: isDark, showDivider: index < min(doses.count - 1, 1), isGraphite: isGraphite)
                }
            }
            .padding(.top, 4)
            
            Spacer(minLength: 0)
        }
    }
}

struct LargeWidgetView: View {
    var doses: [MedicationDose]
    var isDark: Bool
    var isGraphite: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeaderView(isDark: isDark, isGraphite: isGraphite)
            
            Text("Próximas Tomas")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(isDark ? Color.white : Color.black)
                .padding(.bottom, 12)
                .padding(.top, 4)
            
            VStack(spacing: 12) {
                ForEach(Array(doses.enumerated()), id: \.element.id) { index, dose in
                    DoseRowView(dose: dose, isDark: isDark, showDivider: index < doses.count - 1, isGraphite: isGraphite)
                }
            }
            
            Spacer(minLength: 0)
        }
    }
}

struct AuraWidgetsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var isDark: Bool {
        let activeTheme = entry.activeTheme
        return activeTheme == "pureBlack" || activeTheme == "dark" || activeTheme == "graphite"
    }
    
    var isGraphite: Bool {
        return entry.activeTheme == "graphite"
    }

    var body: some View {
        Group {
            if entry.upcomingDoses.isEmpty {
                EmptyStateView(isDark: isDark, isSmall: family == .systemSmall)
            } else {
                switch family {
                case .systemSmall:
                    SmallMedicationView(dose: entry.upcomingDoses.first!, isDark: isDark, isGraphite: isGraphite)
                case .systemMedium:
                    MediumWidgetView(doses: entry.upcomingDoses, isDark: isDark, isGraphite: isGraphite)
                case .systemLarge:
                    LargeWidgetView(doses: entry.upcomingDoses, isDark: isDark, isGraphite: isGraphite)
                case .systemExtraLarge:
                    LargeWidgetView(doses: entry.upcomingDoses, isDark: isDark, isGraphite: isGraphite)
                default:
                    SmallMedicationView(dose: entry.upcomingDoses.first!, isDark: isDark, isGraphite: isGraphite)
                }
            }
        }
    }
}

struct AuraWidgets: Widget {
    let kind: String = "AuraWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                AuraWidgetsEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        AuraWidgetsBackground(activeTheme: entry.activeTheme)
                    }
            } else {
                AuraWidgetsEntryView(entry: entry)
                    .padding()
                    .background(AuraWidgetsBackground(activeTheme: entry.activeTheme))
            }
        }
        .configurationDisplayName("Próxima Toma")
        .description("Mira y registra tus próximas medicaciones rápidamente.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
