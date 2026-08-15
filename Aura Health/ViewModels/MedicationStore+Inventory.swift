//
//  MedicationStore+Inventory.swift
//  Aura Health
//

import Foundation

extension MedicationStore {
    // MARK: - Inventory actions

    func updateInventory(_ inventory: MedicationInventory) {
        var newInv = inventory
        if newInv.profileId == nil {
            newInv.profileId = activeProfileId
        }
        allInventories[newInv.medicationName] = newInv
        updateDerivedState()
        saveState()
    }

    func deductStock(for dose: MedicationDose) {
        let name = dose.medicationName
        guard var inv = allInventories[name] else { return }
        inv.currentStock = max(0, inv.currentStock - dose.amount.numericValue)
        allInventories[name] = inv
        
        if inv.currentStock <= inv.lowStockThreshold {
            NotificationManager.shared.scheduleLowStockAlert(inventory: inv, profiles: profiles)
        }
    }

    func addStock(for dose: MedicationDose) {
        let name = dose.medicationName
        guard var inv = allInventories[name] else { return }
        inv.currentStock += dose.amount.numericValue
        allInventories[name] = inv
    }
}
