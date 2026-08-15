import Foundation
import SwiftUI
import PhotosUI
import Combine

@Observable
final class AddAppointmentViewModel {
    var store: MedicationStore
    var existingAppointment: MedicalAppointment?
    
    // Form state
    var title: String = ""
    var specialty: String = ""
    var date: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    var notes: String = ""
    var attachments: [AppointmentAttachment] = []
    
    // Attachments picker state
    var selectedItem: PhotosPickerItem? = nil {
        didSet {
            if let item = selectedItem {
                handlePhotoSelection(item)
            }
        }
    }
    var isFileImporterPresented = false
    
    // Common specialties for quick selection
    let quickSpecialties = ["Médico de cabecera", "Cardiología", "Traumatología",
                            "Dermatología", "Neurología", "Oftalmología",
                            "Ginecología", "Pediatría", "Análisis", "Otros"]
    
    var isCustomSpecialty: Bool {
        let trimmed = specialty.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !quickSpecialties.contains(trimmed)
    }
    
    var isEditing: Bool { existingAppointment != nil }
    var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }
    
    init(store: MedicationStore, existingAppointment: MedicalAppointment? = nil) {
        self.store = store
        self.existingAppointment = existingAppointment
    }
    
    func loadExistingIfNeeded() {
        guard let appt = existingAppointment else { return }
        title = appt.title
        specialty = appt.specialty ?? ""
        date = appt.date
        notes = appt.notes ?? ""
        attachments = appt.attachments ?? []
    }
    
    func saveAppointment() {
        let spec = specialty.trimmingCharacters(in: .whitespaces)
        let noteContent = notes.trimmingCharacters(in: .whitespaces)
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        
        if let existing = existingAppointment {
            var updated = existing
            updated.title = trimmedTitle
            updated.specialty = spec.isEmpty ? nil : spec
            updated.date = date
            updated.notes = noteContent.isEmpty ? nil : noteContent
            updated.attachments = attachments.isEmpty ? nil : attachments
            store.updateAppointment(updated)
        } else {
            let appt = MedicalAppointment(
                title: trimmedTitle,
                date: date,
                specialty: spec.isEmpty ? nil : spec,
                notes: noteContent.isEmpty ? nil : noteContent,
                attachments: attachments.isEmpty ? nil : attachments
            )
            store.addAppointment(appt)
        }
        
        HapticManager.shared.notification(type: .success)
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let attachment = AttachmentManager.shared.savePhotoAttachment(data: data, originalName: "foto.jpg") {
                    await MainActor.run {
                        attachments.append(attachment)
                    }
                }
            }
        }
    }
    
    func handleFileImport(_ url: URL) {
        if let attachment = AttachmentManager.shared.saveAttachment(from: url) {
            attachments.append(attachment)
        }
    }
    
    func deleteAttachment(_ attachment: AppointmentAttachment) {
        AttachmentManager.shared.deleteLocalFile(for: attachment)
        attachments.removeAll { $0.id == attachment.id }
    }
}
