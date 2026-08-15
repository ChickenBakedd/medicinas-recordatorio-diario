//
//  CloudBackupManager.swift
//  Aura Health
//

import CloudKit
import Foundation
import SwiftUI
import Combine

class CloudBackupManager: ObservableObject {
    static let shared = CloudBackupManager()
    
    @Published var isBackingUp = false
    @Published var isRestoring = false
    @Published var lastBackupDate: Date? = nil
    @Published var backupError: String? = nil
    
    private let recordType = "AuraBackup"
    private let recordName = "UserBackupData"
    private let container = CKContainer.default()
    private var privateDatabase: CKDatabase {
        return container.privateCloudDatabase
    }
    
    private init() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.fetchLastBackupDate()
        }
    }
    
    // MARK: - Backup
    
    func performBackup(from store: MedicationStore, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            self.isBackingUp = true
            self.backupError = nil
        }
        
        let backupData = store.createBackupData()
        
        // Save to temporary file for CKAsset
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("aura_backup.json")
        
        do {
            try backupData.write(to: fileURL)
            
            let recordID = CKRecord.ID(recordName: recordName)
            
            // First try to fetch the existing record to update it
            privateDatabase.fetch(withRecordID: recordID) { [weak self] existingRecord, error in
                guard let self = self else { return }
                
                let recordToSave: CKRecord
                if let existing = existingRecord {
                    recordToSave = existing
                } else {
                    recordToSave = CKRecord(recordType: self.recordType, recordID: recordID)
                }
                
                let asset = CKAsset(fileURL: fileURL)
                recordToSave["backupFile"] = asset
                recordToSave["timestamp"] = Date()
                
                self.privateDatabase.save(recordToSave) { savedRecord, saveError in
                    // Clean up temp file
                    try? FileManager.default.removeItem(at: fileURL)
                    
                    DispatchQueue.main.async {
                        self.isBackingUp = false
                        if let error = saveError {
                            self.backupError = "Error al guardar en iCloud: \(error.localizedDescription)"
                            completion(false)
                        } else {
                            self.lastBackupDate = savedRecord?["timestamp"] as? Date
                            completion(true)
                        }
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isBackingUp = false
                self.backupError = "Error al preparar los datos de respaldo."
                completion(false)
            }
        }
    }
    
    // MARK: - Restore
    
    func performRestore(to store: MedicationStore, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            self.isRestoring = true
            self.backupError = nil
        }
        
        let recordID = CKRecord.ID(recordName: recordName)
        privateDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isRestoring = false
                    self.backupError = "No se encontró copia en iCloud o hubo un error: \(error.localizedDescription)"
                    completion(false)
                }
                return
            }
            
            guard let record = record, let asset = record["backupFile"] as? CKAsset, let fileURL = asset.fileURL else {
                DispatchQueue.main.async {
                    self.isRestoring = false
                    self.backupError = "La copia de seguridad está corrupta o vacía."
                    completion(false)
                }
                return
            }
            
            do {
                let data = try Data(contentsOf: fileURL)
                DispatchQueue.main.async {
                    self.isRestoring = false
                    let success = store.restoreFrom(backupData: data)
                    if success {
                        self.lastBackupDate = record["timestamp"] as? Date
                    } else {
                        self.backupError = "No se pudieron interpretar los datos de la copia."
                    }
                    completion(success)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRestoring = false
                    self.backupError = "Error al leer la copia de iCloud."
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func fetchLastBackupDate() {
        let recordID = CKRecord.ID(recordName: recordName)
        privateDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            if let record = record, let timestamp = record["timestamp"] as? Date {
                DispatchQueue.main.async {
                    self?.lastBackupDate = timestamp
                }
            }
        }
    }
}
