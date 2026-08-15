import AppIntents
import SwiftUI

@available(iOS 17.0, *)
struct TakeMedicationIntent: AppIntent {
    static var title: LocalizedStringResource = "Tomar Medicación"
    static var description: IntentDescription = IntentDescription("Registra que te has tomado tu medicación pendiente.")
    
    // El ID de la dosis que estamos tomando
    @Parameter(title: "Dose ID")
    var doseId: String
    
    init() {}
    
    init(doseId: String) {
        self.doseId = doseId
    }
    
    func perform() async throws -> some IntentResult {
        // Ejecutamos en el MainActor porque MedicationStore requiere acceso en el hilo principal
        await MainActor.run {
            let store = MedicationStore()
            if let uuid = UUID(uuidString: doseId),
               store.allDoses.contains(where: { $0.id == uuid }) {
                
                // Usamos el método oficial de la store que también actualiza inventario, 
                // estadísticas y llama a saveState() que recarga los widgets.
                store.setDoseTaken(id: uuid, taken: true)
                
                // Opcional: Si es un nuevo día en algún lado, resetear
                store.resetIfNewDay()
            }
        }
        
        return .result()
    }
}
