//
//  MedicationStore.swift
//  Aura Health
//

import Foundation
import Observation
import WidgetKit

struct ProfileStats: Codable {
    var totalDosesTakenAllTime: Int = 0
    var perfectDaysCount: Int = 0
    var currentStreakDays: Int = 0
    var lastPerfectDay: Date? = nil
    var lastResetDay: Date = Calendar.current.startOfDay(for: Date())
}

@Observable
final class MedicationStore {
    var profiles: [UserProfile] = []
    var activeProfileId: UUID? = nil
    
    var allDoses: [MedicationDose] = []
    var allAppointments: [MedicalAppointment] = []
    var allInventories: [String: MedicationInventory] = [:]
    var allVitals: [HealthMetric] = []
    
    var profileStats: [UUID: ProfileStats] = [:]
    
    // Derived for active profile (cached for performance)
    var doses: [MedicationDose] = []
    var appointments: [MedicalAppointment] = []
    var inventories: [String: MedicationInventory] = [:]
    var vitals: [HealthMetric] = []
    
    /// Recalculates derived state from raw data. Call explicitly after mutations.
    func updateDerivedState() {
        doses = allDoses.filter { $0.profileId == activeProfileId }.sorted { $0.scheduledTime < $1.scheduledTime }
        appointments = allAppointments.filter { $0.profileId == activeProfileId }.sorted { $0.date < $1.date }
        inventories = allInventories.filter { $1.profileId == activeProfileId }
        vitals = allVitals.filter { $0.profileId == activeProfileId }.sorted { $0.date > $1.date }
    }
    
    /// Serial queue to ensure saveState writes are atomic and ordered.
    let persistenceQueue = DispatchQueue(label: "com.aura.persistence", qos: .utility)
    
    var currentStats: ProfileStats {
        get {
            guard let id = activeProfileId else { return ProfileStats() }
            return profileStats[id] ?? ProfileStats()
        }
        set {
            if let id = activeProfileId {
                profileStats[id] = newValue
            }
        }
    }
    
    // Active Profile Stats accessors
    var totalDosesTakenAllTime: Int {
        get { currentStats.totalDosesTakenAllTime }
        set { currentStats.totalDosesTakenAllTime = newValue }
    }
    var perfectDaysCount: Int {
        get { currentStats.perfectDaysCount }
        set { currentStats.perfectDaysCount = newValue }
    }
    var currentStreakDays: Int {
        get { currentStats.currentStreakDays }
        set { currentStats.currentStreakDays = newValue }
    }
    var lastPerfectDay: Date? {
        get { currentStats.lastPerfectDay }
        set { currentStats.lastPerfectDay = newValue }
    }
    var lastResetDay: Date {
        get { currentStats.lastResetDay }
        set { currentStats.lastResetDay = newValue }
    }
    
    // Mock Data for Charts
    struct DailyAdherence: Identifiable {
        var id = UUID()
        var date: Date
        var percentage: Double
        var missedMedications: [String] = []
    }
    
    struct MedicationHistoricalData: Identifiable {
        var id = UUID()
        var name: String
        var totalDoses: Int
    }
    
    var mockAdherenceHistory: [DailyAdherence] = {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let percentage: Double
            var missed: [String] = []
            switch dayOffset {
            case 6: percentage = 0.6; missed = ["Ibuprofeno", "Atorvastatina"]
            case 4: percentage = 0.8; missed = ["Paracetamol"]
            default: percentage = 1.0
            }
            return DailyAdherence(date: date, percentage: percentage, missedMedications: missed)
        }
    }()
    
    var mockMedicationBreakdown: [MedicationHistoricalData] = [
        MedicationHistoricalData(name: "Omeprazol", totalDoses: 85),
        MedicationHistoricalData(name: "Ibuprofeno", totalDoses: 42),
        MedicationHistoricalData(name: "Paracetamol", totalDoses: 15)
    ]
    
    // Persistence Keys
    let dosesKey = "aura_doses"
    let appointmentsKey = "aura_appointments"
    let inventoriesKey = "aura_inventories"
    let vitalsKey = "aura_vitals"
    let statsKey = "aura_profile_stats"
    let profilesKey = "aura_profiles"
    let activeProfileKey = "aura_active_profile"
    let didMigrateToAppGroupKey = "aura_did_migrate_app_group"

    // App Group UserDefaults
    let sharedDefaults = UserDefaults(suiteName: "group.com.jmrsoft.medicinas") ?? UserDefaults.standard

    init() {
        _ = loadState()
    }
    
    /// Call after the UI has appeared to start background services without blocking launch.
    func startBackgroundServices() {
        WatchSyncManager.shared.startSession(with: self)
    }
    
    // MARK: - Computed (Active Profile)

    var totalDosesToday: Int { doses.count }

    var takenDosesToday: Int {
        doses.filter(\.isTaken).count
    }

    var progress: Double {
        guard totalDosesToday > 0 else { return 0 }
        return Double(takenDosesToday) / Double(totalDosesToday)
    }

    var currentDose: MedicationDose? {
        return doses.filter { !$0.isTaken }.sorted { $0.scheduledTime < $1.scheduledTime }.first
    }

    var allDosesTaken: Bool {
        return !doses.isEmpty && doses.allSatisfy(\.isTaken)
    }

    var dosesSortedByTime: [MedicationDose] {
        doses.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    var appointmentsSortedByDate: [MedicalAppointment] {
        appointments.sorted { $0.date < $1.date }
    }
    

    // MARK: - Private
    func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let calendar = Calendar.current
        
        var updatedDoses = allDoses
        var didChangeDoses = false
        
        // Update stats for all profiles
        for profile in profiles {
            var stats = profileStats[profile.id] ?? ProfileStats()
            
            if !calendar.isDate(today, inSameDayAs: stats.lastResetDay) {
                let pDoses = allDoses.filter { $0.profileId == profile.id }
                let pTotal = pDoses.count
                let pTaken = pDoses.filter(\.isTaken).count
                
                if pTotal > 0 && pTaken == pTotal {
                    stats.perfectDaysCount += 1
                    if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                       let lastPerfect = stats.lastPerfectDay,
                       calendar.isDate(lastPerfect, inSameDayAs: yesterday) {
                        stats.currentStreakDays += 1
                    } else {
                        stats.currentStreakDays = 1
                    }
                    stats.lastPerfectDay = stats.lastResetDay
                } else {
                    stats.currentStreakDays = 0
                }
                
                stats.lastResetDay = today
                profileStats[profile.id] = stats
                
                // Batch-reset doses for THIS profile
                for index in updatedDoses.indices where updatedDoses[index].profileId == profile.id {
                    updatedDoses[index].isTaken = false
                    let oldTime = updatedDoses[index].scheduledTime
                    let components = calendar.dateComponents([.hour, .minute, .second], from: oldTime)
                    if let newTime = calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: components.second ?? 0, of: today) {
                        updatedDoses[index].scheduledTime = newTime
                    }
                }
                didChangeDoses = true
            }
        }
        
        if didChangeDoses {
            allDoses = updatedDoses
            updateDerivedState()
            saveState()
        }
    }
    
    var distinctMedicationNames: Set<String> {
        Set(doses.map { $0.medicationName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
    }
    
    func canAddMoreMedications(named name: String) -> Bool {
        if PremiumManager.shared.isPro { return true }
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if distinctMedicationNames.contains(cleanName) {
            return true // Editing or adding doses for an existing medication is allowed
        }
        return distinctMedicationNames.count < 3
    }
    
    func canGenerateFreeReport(for profileId: UUID) -> Bool {
        return PremiumManager.shared.isPro
    }
    
    func markFreeReportGenerated(for profileId: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == profileId }) {
            profiles[index].lastFreeReportDate = Date()
            saveState()
        }
    }
}

