import Foundation

final class AttachmentManager {
    static let shared = AttachmentManager()
    
    private init() {}
    
    private var attachmentsFolderURL: URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let folderURL = documentsURL.appendingPathComponent("attachments", isDirectory: true)
        if !fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL
    }
    
    func saveAttachment(from url: URL) -> AppointmentAttachment? {
        guard let folderURL = attachmentsFolderURL else { return nil }
        
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileExtension = url.pathExtension
        let uniqueName = "\(UUID().uuidString).\(fileExtension)"
        let destinationURL = folderURL.appendingPathComponent(uniqueName)
        
        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return AppointmentAttachment(
                id: UUID(),
                originalName: url.lastPathComponent,
                fileType: fileExtension.lowercased() == "pdf" ? "pdf" : "document",
                relativePath: "attachments/\(uniqueName)"
            )
        } catch {
            print("Error saving attachment: \(error)")
            return nil
        }
    }
    
    func savePhotoAttachment(data: Data, originalName: String) -> AppointmentAttachment? {
        guard let folderURL = attachmentsFolderURL else { return nil }
        
        let uniqueName = "\(UUID().uuidString).jpg"
        let destinationURL = folderURL.appendingPathComponent(uniqueName)
        
        do {
            try data.write(to: destinationURL)
            return AppointmentAttachment(
                id: UUID(),
                originalName: originalName,
                fileType: "image",
                relativePath: "attachments/\(uniqueName)"
            )
        } catch {
            print("Error saving photo attachment: \(error)")
            return nil
        }
    }
    
    func deleteLocalFile(for attachment: AppointmentAttachment) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent(attachment.relativePath)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func getFullAttachmentURL(for attachment: AppointmentAttachment) -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsURL.appendingPathComponent(attachment.relativePath)
    }
}
