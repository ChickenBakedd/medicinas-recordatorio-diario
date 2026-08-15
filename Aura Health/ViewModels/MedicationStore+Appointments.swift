//
//  MedicationStore+Appointments.swift
//  Aura Health
//

import Foundation

extension MedicationStore {
    // MARK: - Appointment actions

    func addAppointment(_ appt: MedicalAppointment) {
        var newAppt = appt
        if newAppt.profileId == nil {
            newAppt.profileId = activeProfileId
        }
        allAppointments.append(newAppt)
        NotificationManager.shared.scheduleAppointment(appt: newAppt, profiles: profiles)
        updateDerivedState()
        saveState()
    }

    func updateAppointment(_ appt: MedicalAppointment) {
        guard let index = allAppointments.firstIndex(where: { $0.id == appt.id }) else { return }
        allAppointments[index] = appt
        NotificationManager.shared.cancelAppointment(id: appt.id)
        NotificationManager.shared.scheduleAppointment(appt: appt, profiles: profiles)
        updateDerivedState()
        saveState()
    }

    func deleteAppointment(id: UUID) {
        allAppointments.removeAll { $0.id == id }
        NotificationManager.shared.cancelAppointment(id: id)
        updateDerivedState()
        saveState()
    }
}
