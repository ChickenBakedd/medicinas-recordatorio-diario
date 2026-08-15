//
//  NotificationManager.swift
//  Aura Health
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }
    
    func requestPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
    
    // MARK: - Preferences
    private var isGlobalEnabled: Bool {
        UserDefaults.standard.object(forKey: "globalNotificationsEnabled") as? Bool ?? true
    }
    private var isMedEnabled: Bool {
        UserDefaults.standard.object(forKey: "medNotificationsEnabled") as? Bool ?? true
    }
    private var medAdvanceMins: Int {
        UserDefaults.standard.object(forKey: "medAdvanceMins") as? Int ?? 0
    }
    private var isApptEnabled: Bool {
        UserDefaults.standard.object(forKey: "apptNotificationsEnabled") as? Bool ?? true
    }
    
    func rescheduleAll(doses: [MedicationDose], appointments: [MedicalAppointment], profiles: [UserProfile]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard isGlobalEnabled else { return }
        
        if isMedEnabled {
            for dose in doses {
                scheduleMedication(dose: dose, profiles: profiles)
            }
        }
        
        if isApptEnabled {
            for appt in appointments {
                scheduleAppointment(appt: appt, profiles: profiles)
            }
        }
    }
    
    // MARK: - Medication Notifications
    
    func scheduleMedication(dose: MedicationDose, profiles: [UserProfile]) {
        guard isGlobalEnabled && isMedEnabled else { return }
        let center = UNUserNotificationCenter.current()
        let identifier = dose.id.uuidString
        
        let content = UNMutableNotificationContent()
        content.title = "Hora de tu medicación"
        
        var amountText = "una dosis"
        switch dose.amount {
        case .half: amountText = "media dosis"
        case .one: amountText = "1 dosis"
        case .oneAndHalf: amountText = "1 dosis y media"
        case .two: amountText = "2 dosis"
        case .twoAndHalf: amountText = "2 dosis y media"
        case .three: amountText = "3 dosis"
        case .threeAndHalf: amountText = "3 dosis y media"
        case .four: amountText = "4 dosis"
        }
        
        // Use generic forms for readability, or you can tailor per form:
        if dose.form == .pill {
            amountText = amountText.replacingOccurrences(of: "dosis", with: "pastilla")
        } else if dose.form == .syrup {
            amountText = amountText.replacingOccurrences(of: "dosis", with: "cucharada")
        }
        
        var baseText = "Toca tomar \(amountText) de \(dose.medicationName)"
        if let pid = dose.profileId, let profile = profiles.first(where: { $0.id == pid }) {
            baseText += " (\(profile.name))."
        } else {
            baseText += "."
        }
        
        content.body = baseText
        content.sound = .default
        
        // Extract hour and minute and apply advance time
        let calendar = Calendar.current
        var targetDate = dose.scheduledTime
        if medAdvanceMins > 0 {
            targetDate = calendar.date(byAdding: .minute, value: -medAdvanceMins, to: targetDate) ?? targetDate
        }
        let components = calendar.dateComponents([.hour, .minute], from: targetDate)
        
        // Schedule daily
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling medication notification: \(error)")
            }
        }
    }
    
    func cancelMedication(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
    
    // MARK: - Appointment Notifications
    
    func scheduleAppointment(appt: MedicalAppointment, profiles: [UserProfile]) {
        guard isGlobalEnabled && isApptEnabled else { return }
        let center = UNUserNotificationCenter.current()
        
        // Base identifiers
        let oneDayId = "\(appt.id.uuidString)-1day"
        let oneHourId = "\(appt.id.uuidString)-1hour"
        
        let calendar = Calendar.current
        let now = Date()
        
        // 1 Day before
        if let oneDayBefore = calendar.date(byAdding: .day, value: -1, to: appt.date), oneDayBefore > now {
            let content = UNMutableNotificationContent()
            content.title = "Cita médica mañana"
            var baseText = "Recuerda que mañana tienes tu cita: \(appt.title)"
            if let spec = appt.specialty {
                baseText += " (\(spec))"
            }
            if let pid = appt.profileId, let profile = profiles.first(where: { $0.id == pid }) {
                baseText += " para \(profile.name)."
            } else {
                baseText += "."
            }
            content.body = baseText
            content.sound = .default
            
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: oneDayBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: oneDayId, content: content, trigger: trigger)
            center.add(request)
        }
        
        // 1 Hour before
        if let oneHourBefore = calendar.date(byAdding: .hour, value: -1, to: appt.date), oneHourBefore > now {
            let content = UNMutableNotificationContent()
            content.title = "Cita médica en 1 hora"
            var baseText = "Tienes tu cita en breve: \(appt.title)"
            if let pid = appt.profileId, let profile = profiles.first(where: { $0.id == pid }) {
                baseText += " para \(profile.name)."
            } else {
                baseText += "."
            }
            content.body = baseText
            content.sound = .default
            
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: oneHourBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: oneHourId, content: content, trigger: trigger)
            center.add(request)
        }
    }
    
    func cancelAppointment(id: UUID) {
        let oneDayId = "\(id.uuidString)-1day"
        let oneHourId = "\(id.uuidString)-1hour"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [oneDayId, oneHourId])
    }
    
    // MARK: - Inventory Notifications
    
    func scheduleLowStockAlert(inventory: MedicationInventory, profiles: [UserProfile]) {
        guard isGlobalEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        let identifier = "lowStock-\(inventory.medicationName)"
        
        // Remove any existing alert for this medication so we don't spam
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Inventario Bajo"
        var baseText = "Te quedan \(Int(inventory.currentStock)) dosis de \(inventory.medicationName)."
        if let pid = inventory.profileId, let profile = profiles.first(where: { $0.id == pid }) {
            baseText = "A \(profile.name) le quedan \(Int(inventory.currentStock)) dosis de \(inventory.medicationName)."
        }
        content.body = baseText + " Recuerda ir a la farmacia pronto."
        content.sound = .default
        
        // Schedule for tomorrow at 17:00 PM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        components.hour = 17
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling low stock alert: \(error)")
            }
        }
    }
}
