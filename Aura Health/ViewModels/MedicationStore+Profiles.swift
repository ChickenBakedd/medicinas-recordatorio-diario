//
//  MedicationStore+Profiles.swift
//  Aura Health
//

import Foundation

extension MedicationStore {
    var activeProfile: UserProfile? {
        profiles.first { $0.id == activeProfileId }
    }

    // MARK: - Profiles Actions
    
    func addProfile(_ profile: UserProfile) {
        profiles.append(profile)
        profileStats[profile.id] = ProfileStats()
        saveState()
    }
    
    func updateProfile(_ profile: UserProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        saveState()
    }
    
    func deleteProfile(id: UUID) {
        guard profiles.count > 1 else { return }
        guard profiles.first(where: { $0.id == id })?.isMain != true else { return }
        
        for dose in allDoses where dose.profileId == id {
            NotificationManager.shared.cancelMedication(id: dose.id)
        }
        for appt in allAppointments where appt.profileId == id {
            NotificationManager.shared.cancelAppointment(id: appt.id)
        }
        
        profiles.removeAll { $0.id == id }
        allDoses.removeAll { $0.profileId == id }
        allAppointments.removeAll { $0.profileId == id }
        allInventories = allInventories.filter { $1.profileId != id }
        allVitals.removeAll { $0.profileId == id }
        profileStats.removeValue(forKey: id)
        if activeProfileId == id {
            activeProfileId = profiles.first?.id
        }
        updateDerivedState()
        saveState()
    }
}
