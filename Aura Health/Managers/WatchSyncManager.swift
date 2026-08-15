//
//  WatchSyncManager.swift
//  Aura Health
//

import Foundation
import WatchConnectivity
import Combine

class WatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSyncManager()
    
    // We keep a weak reference to MedicationStore to tell it to mark doses as taken
    weak var store: MedicationStore?
    
    private override init() {
        super.init()
    }
    
    func startSession(with store: MedicationStore) {
        self.store = store
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func syncState(doses: [MedicationDose], profiles: [UserProfile]) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        
        // We only send the active doses and profiles to keep the payload small
        let encoder = JSONEncoder()
        do {
            let dosesData = try encoder.encode(doses)
            let profilesData = try encoder.encode(profiles)
            
            let context: [String: Any] = [
                "doses": dosesData,
                "profiles": profilesData,
                "isPro": PremiumManager.shared.isPro
            ]
            
            try WCSession.default.updateApplicationContext(context)
        } catch {
            print("Error encoding sync state for watch: \(error)")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let store = store {
            // Send initial state upon activation
            syncState(doses: store.allDoses, profiles: store.profiles)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // No-op
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate for background transfers
        WCSession.default.activate()
    }
    
    // Handle messages from the watch (like marking a dose as taken)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleMessage(userInfo)
    }
    
    private func handleMessage(_ message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let store = self.store else { return }
            
            if message["action"] as? String == "setTaken",
               let doseIdString = message["doseId"] as? String,
               let doseId = UUID(uuidString: doseIdString),
               let taken = message["taken"] as? Bool {
                
                store.setDoseTaken(id: doseId, taken: taken)
                // Sync back the updated state to the watch
                self.syncState(doses: store.allDoses, profiles: store.profiles)
            }
        }
    }
}
