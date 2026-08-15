//
//  MedicationStore+Vitals.swift
//  Aura Health
//

import Foundation

extension MedicationStore {
    // MARK: - Vitals
    
    func addVital(_ metric: HealthMetric) {
        allVitals.append(metric)
        updateDerivedState()
        saveState()
    }
}
