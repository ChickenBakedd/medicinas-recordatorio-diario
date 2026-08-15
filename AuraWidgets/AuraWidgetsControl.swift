import AppIntents
import SwiftUI
import WidgetKit

struct AuraWidgetsControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.jmrsoft.medicinas.AuraWidgetsControl",
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Recordatorio",
                isOn: value,
                action: ToggleRemindersIntent()
            ) { isRunning in
                Label(isRunning ? "Activo" : "Pausado", systemImage: "pill.fill")
            }
        }
        .displayName("Medicinas")
        .description("Control rápido para tus recordatorios de medicinas.")
    }
}

extension AuraWidgetsControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool {
            true
        }

        func currentValue() async throws -> Bool {
            return true
        }
    }
}

struct ToggleRemindersIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Recordatorio de Medicinas"

    @Parameter(title: "Recordatorios activos")
    var value: Bool

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
