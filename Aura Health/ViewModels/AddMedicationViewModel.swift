import SwiftUI
import Observation

enum AddMedicationInputMode: CaseIterable, Hashable {
    case manual, camera
}

@Observable
final class AddMedicationViewModel {
    var store: MedicationStore
    var existingDose: MedicationDose?
    
    // Form state
    var name: String = ""
    var mgText: String = ""
    var selectedForm: DoseForm = .pill
    var wholeAmount: Int = 1      // 0 = sólo media, 1-4 entero
    var addHalf: Bool = false      // añadir media unidad
    var scheduledTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    
    // Stock Control
    var trackStock: Bool = false
    var initialStock: String = ""
    var lowStockThreshold: String = "3"
    
    // UI state
    var showCamera = false
    var inputMode: AddMedicationInputMode = .manual
    
    var isEditing: Bool { existingDose != nil }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    var selectedAmount: DoseAmount { DoseAmount.make(whole: wholeAmount, half: addHalf) }
    
    init(store: MedicationStore, existingDose: MedicationDose? = nil) {
        self.store = store
        self.existingDose = existingDose
    }
    
    func loadExistingIfNeeded() {
        if let existing = existingDose {
            name = existing.medicationName
            if let mg = existing.milligrams { mgText = "\(mg)" }
            selectedForm = existing.form
            
            switch existing.amount {
            case .half: wholeAmount = 0; addHalf = true
            case .one: wholeAmount = 1; addHalf = false
            case .oneAndHalf: wholeAmount = 1; addHalf = true
            case .two: wholeAmount = 2; addHalf = false
            case .twoAndHalf: wholeAmount = 2; addHalf = true
            case .three: wholeAmount = 3; addHalf = false
            case .threeAndHalf: wholeAmount = 3; addHalf = true
            case .four: wholeAmount = 4; addHalf = false
            }
            scheduledTime = existing.scheduledTime
            
            // Load inventory if it exists
            if let inv = store.inventories[existing.medicationName] {
                trackStock = true
                initialStock = String(format: "%g", inv.currentStock)
                lowStockThreshold = String(format: "%g", inv.lowStockThreshold)
            }
        }
    }
    
    func saveDose() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let mg = Int(mgText.trimmingCharacters(in: .whitespaces))
        let amount = selectedAmount
        
        if let existing = existingDose {
            var updated = existing
            updated.medicationName = trimmedName
            updated.milligrams = mg
            updated.form = selectedForm
            updated.amount = amount
            updated.scheduledTime = scheduledTime
            store.updateDose(updated)
        } else {
            let newDose = MedicationDose(
                medicationName: trimmedName,
                amount: amount,
                milligrams: mg,
                form: selectedForm,
                scheduledTime: scheduledTime
            )
            store.addDose(newDose)
        }
        
        // Handle Stock
        if trackStock {
            if let current = Double(initialStock.replacingOccurrences(of: ",", with: ".")),
               let threshold = Double(lowStockThreshold.replacingOccurrences(of: ",", with: ".")) {
                let inventory = MedicationInventory(
                    medicationName: trimmedName,
                    currentStock: current,
                    lowStockThreshold: threshold
                )
                store.updateInventory(inventory)
            }
        }
        
        HapticManager.shared.notification(type: .success)
    }
    
    func handleScanResult(_ result: OCRMedicationResult) {
        name = result.name
        if let mg = result.milligrams { mgText = "\(mg)" }
        inputMode = .manual // switch to manual to review
    }
}
