//
//  MedicationStore+Doses.swift
//  Aura Health
//

import Foundation

extension MedicationStore {
    // MARK: - Dose actions

    func registerCurrentDose() {
        guard let current = currentDose,
              let index = allDoses.firstIndex(where: { $0.id == current.id }) else { return }
        allDoses[index].isTaken = true
        if allDoses[index].profileId == activeProfileId {
            totalDosesTakenAllTime += 1
        }
        deductStock(for: current)
        updateDerivedState()
        saveState()
        
        NotificationCenter.default.post(name: NSNotification.Name("DoseLogged"), object: nil)
    }

    func setDoseTaken(id: UUID, taken: Bool) {
        guard let index = allDoses.firstIndex(where: { $0.id == id }) else { return }
        let wasTaken = allDoses[index].isTaken
        
        if wasTaken != taken {
            allDoses[index].isTaken = taken
            if taken {
                if allDoses[index].profileId == activeProfileId {
                    totalDosesTakenAllTime += 1
                }
                deductStock(for: allDoses[index])
                NotificationCenter.default.post(name: NSNotification.Name("DoseLogged"), object: nil)
            } else {
                if allDoses[index].profileId == activeProfileId {
                    totalDosesTakenAllTime = max(0, totalDosesTakenAllTime - 1)
                }
                addStock(for: allDoses[index])
            }
            updateDerivedState()
            saveState()
        }
    }

    func addDose(_ dose: MedicationDose) {
        var newDose = dose
        if newDose.profileId == nil {
            newDose.profileId = activeProfileId
        }
        allDoses.append(newDose)
        NotificationManager.shared.scheduleMedication(dose: newDose, profiles: profiles)
        updateDerivedState()
        saveState()
    }

    func updateDose(_ dose: MedicationDose) {
        guard let index = allDoses.firstIndex(where: { $0.id == dose.id }) else { return }
        allDoses[index] = dose
        NotificationManager.shared.cancelMedication(id: dose.id)
        NotificationManager.shared.scheduleMedication(dose: dose, profiles: profiles)
        updateDerivedState()
        saveState()
    }

    func deleteDose(id: UUID) {
        allDoses.removeAll { $0.id == id }
        NotificationManager.shared.cancelMedication(id: id)
        updateDerivedState()
        saveState()
    }
}
