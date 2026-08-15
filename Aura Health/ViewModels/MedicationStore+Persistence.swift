//
//  MedicationStore+Persistence.swift
//  Aura Health
//

import Foundation
import WidgetKit

extension MedicationStore {
    
    private var secureStoreURL: URL {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jmrsoft.medicinas") ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return container.appendingPathComponent("secure_medication_store.json")
    }

    // MARK: - App Group Migration
    
    private func migrateToAppGroupIfNeeded() {
        if sharedDefaults.bool(forKey: didMigrateToAppGroupKey) { return }
        
        let keys = [dosesKey, appointmentsKey, inventoriesKey, vitalsKey, statsKey, profilesKey, activeProfileKey, "aura_stats"]
        for key in keys {
            if let obj = UserDefaults.standard.object(forKey: key) {
                sharedDefaults.set(obj, forKey: key)
            }
        }
        
        sharedDefaults.set(true, forKey: didMigrateToAppGroupKey)
    }
    
    // MARK: - iCloud Backup
    
    struct BackupPayload: Codable {
        let profiles: Data?
        let activeProfileKey: String?
        let doses: Data?
        let appointments: Data?
        let inventories: Data?
        let vitals: Data?
        let stats: Data?
    }
    
    // MARK: - Persistence

    func saveState() {
        let payload = BackupPayload(
            profiles: try? JSONEncoder().encode(profiles),
            activeProfileKey: activeProfileId?.uuidString,
            doses: try? JSONEncoder().encode(allDoses),
            appointments: try? JSONEncoder().encode(allAppointments),
            inventories: try? JSONEncoder().encode(allInventories),
            vitals: try? JSONEncoder().encode(allVitals),
            stats: try? JSONEncoder().encode(profileStats)
        )
        
        // Encode payload on the main actor to avoid Swift 6 concurrency warnings
        guard let payloadData = try? JSONEncoder().encode(payload) else {
            WatchSyncManager.shared.syncState(doses: allDoses, profiles: profiles)
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        
        let fileURL = self.secureStoreURL
        persistenceQueue.async {
            do {
                // Save with hardware encryption (inaccessible when device is locked)
                try payloadData.write(to: fileURL, options: .completeFileProtection)
            } catch {
                print("Error saving secure state: \(error)")
            }
        }
        
        WatchSyncManager.shared.syncState(doses: allDoses, profiles: profiles)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadState() -> Bool {
        migrateToAppGroupIfNeeded()
        
        var loadedSomething = false
        var payload: BackupPayload? = nil
        
        // 1. Try loading from secure file
        if let fileData = try? Data(contentsOf: secureStoreURL),
           let decodedPayload = try? JSONDecoder().decode(BackupPayload.self, from: fileData) {
            payload = decodedPayload
        } 
        // 2. Migration from UserDefaults
        else {
            let legacyPayload = BackupPayload(
                profiles: sharedDefaults.data(forKey: profilesKey),
                activeProfileKey: sharedDefaults.string(forKey: activeProfileKey),
                doses: sharedDefaults.data(forKey: dosesKey),
                appointments: sharedDefaults.data(forKey: appointmentsKey),
                inventories: sharedDefaults.data(forKey: inventoriesKey),
                vitals: sharedDefaults.data(forKey: vitalsKey),
                stats: sharedDefaults.data(forKey: statsKey)
            )
            
            // Si hay datos reales de migración
            if legacyPayload.profiles != nil || legacyPayload.doses != nil {
                payload = legacyPayload
                
                // Limpiar UserDefaults para no dejar datos sensibles sin cifrar
                let keys = [dosesKey, appointmentsKey, inventoriesKey, vitalsKey, statsKey, profilesKey, activeProfileKey, "aura_stats"]
                for key in keys {
                    sharedDefaults.removeObject(forKey: key)
                }
                
                // Forzar guardado en el nuevo archivo cifrado
                DispatchQueue.main.async {
                    self.saveState()
                }
            }
        }
        
        guard let finalPayload = payload else {
            // New user initialization
            let mainProfile = UserProfile(id: UUID(), name: "Mi Perfil", avatarColor: "blue", isMain: true)
            self.profiles = [mainProfile]
            self.activeProfileId = mainProfile.id
            updateDerivedState()
            return false
        }
        
        // Decode Profiles
        if let data = finalPayload.profiles,
           let savedProfiles = try? JSONDecoder().decode([UserProfile].self, from: data),
           !savedProfiles.isEmpty {
            self.profiles = savedProfiles
            loadedSomething = true
        } else {
            let mainProfile = UserProfile(id: UUID(), name: "Mi Perfil", avatarColor: "blue", isMain: true)
            self.profiles = [mainProfile]
        }
        
        // Active Profile
        if let idString = finalPayload.activeProfileKey,
           let id = UUID(uuidString: idString) {
            self.activeProfileId = id
        } else {
            self.activeProfileId = profiles.first?.id
        }
        
        // Doses
        if let data = finalPayload.doses,
           let savedDoses = try? JSONDecoder().decode([MedicationDose].self, from: data) {
            self.allDoses = savedDoses.map { d in
                var dose = d
                if dose.profileId == nil { dose.profileId = self.activeProfileId }
                return dose
            }
            loadedSomething = true
        }
        
        // Appointments
        if let data = finalPayload.appointments,
           let savedAppointments = try? JSONDecoder().decode([MedicalAppointment].self, from: data) {
            self.allAppointments = savedAppointments.map { a in
                var appt = a
                if appt.profileId == nil { appt.profileId = self.activeProfileId }
                return appt
            }
            loadedSomething = true
        }
        
        // Inventories
        if let data = finalPayload.inventories,
           let savedInventories = try? JSONDecoder().decode([String: MedicationInventory].self, from: data) {
            var migratedInventories = [String: MedicationInventory]()
            for (key, value) in savedInventories {
                var inv = value
                if inv.profileId == nil { inv.profileId = self.activeProfileId }
                migratedInventories[key] = inv
            }
            self.allInventories = migratedInventories
            loadedSomething = true
        }
        
        // Vitals
        if let data = finalPayload.vitals,
           let savedVitals = try? JSONDecoder().decode([HealthMetric].self, from: data) {
            self.allVitals = savedVitals
            loadedSomething = true
        }
        
        // Stats
        if let data = finalPayload.stats,
           let stats = try? JSONDecoder().decode([UUID: ProfileStats].self, from: data) {
            self.profileStats = stats
            loadedSomething = true
        } else {
            struct OldStoreStats: Codable {
                let totalDosesTakenAllTime: Int
                let perfectDaysCount: Int
                let currentStreakDays: Int
                let lastPerfectDay: Date?
                let lastResetDay: Date
            }
            if let data = sharedDefaults.data(forKey: "aura_stats"),
               let oldStats = try? JSONDecoder().decode(OldStoreStats.self, from: data),
               let mainId = self.activeProfileId {
                
                var newStats = ProfileStats()
                newStats.totalDosesTakenAllTime = oldStats.totalDosesTakenAllTime
                newStats.perfectDaysCount = oldStats.perfectDaysCount
                newStats.currentStreakDays = oldStats.currentStreakDays
                newStats.lastPerfectDay = oldStats.lastPerfectDay
                newStats.lastResetDay = oldStats.lastResetDay
                self.profileStats[mainId] = newStats
            } else if let mainId = self.activeProfileId {
                self.profileStats[mainId] = ProfileStats()
            }
        }
        
        if loadedSomething {
            resetIfNewDay()
        }
        
        updateDerivedState()
        return loadedSomething
    }
    
    func createBackupData() -> Data {
        // Save current state first to ensure we backup latest changes
        saveState()
        
        if let data = try? Data(contentsOf: secureStoreURL) {
            return data
        }
        return Data()
    }
    
    func restoreFrom(backupData: Data) -> Bool {
        do {
            try backupData.write(to: secureStoreURL, options: .completeFileProtection)
            let _ = loadState()
            WatchSyncManager.shared.syncState(doses: allDoses, profiles: profiles)
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch {
            print("Restore failed: \(error)")
            return false
        }
    }
}
