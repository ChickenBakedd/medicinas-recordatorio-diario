//
//  ReviewManager.swift
//  Aura Health
//

import Foundation
import StoreKit
import SwiftUI

class ReviewManager {
    static let shared = ReviewManager()
    
    @AppStorage("firstLaunchDate") private var firstLaunchDate: Double = 0
    @AppStorage("activeDaysSet") private var activeDaysSetData: Data = Data()
    @AppStorage("loggedDosesCount") private var loggedDosesCount: Int = 0
    @AppStorage("lastPromptedThreshold") private var lastPromptedThreshold: Int = 0
    
    private init() {
        if firstLaunchDate == 0 {
            firstLaunchDate = Date().timeIntervalSince1970
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DoseLogged"), object: nil, queue: .main) { [weak self] _ in
            self?.doseLogged()
        }
    }
    
    private var activeDaysSet: Set<String> {
        get {
            guard let array = try? JSONDecoder().decode([String].self, from: activeDaysSetData) else { return [] }
            return Set(array)
        }
        set {
            if let data = try? JSONEncoder().encode(Array(newValue)) {
                activeDaysSetData = data
            }
        }
    }
    
    func appOpened() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        
        var currentDays = activeDaysSet
        if !currentDays.contains(todayString) {
            currentDays.insert(todayString)
            activeDaysSet = currentDays
        }
    }
    
    func doseLogged() {
        loggedDosesCount += 1
        checkAndPromptForReview()
    }
    
    private func checkAndPromptForReview() {
        let activeDaysCount = activeDaysSet.count
        let doses = loggedDosesCount
        
        var shouldPrompt = false
        
        // Strategy: Hybrid
        // 1st prompt: >= 3 days AND >= 5 doses
        // 2nd prompt: >= 30 days AND >= 30 doses
        // 3rd prompt: >= 90 days AND >= 90 doses
        
        if activeDaysCount >= 3 && doses >= 5 && lastPromptedThreshold < 1 {
            shouldPrompt = true
            lastPromptedThreshold = 1
        } else if activeDaysCount >= 30 && doses >= 30 && lastPromptedThreshold < 2 {
            shouldPrompt = true
            lastPromptedThreshold = 2
        } else if activeDaysCount >= 90 && doses >= 90 && lastPromptedThreshold < 3 {
            shouldPrompt = true
            lastPromptedThreshold = 3
        }
        
        if shouldPrompt {
            DispatchQueue.main.async {
                self.requestReview()
            }
        }
    }
    
    private func requestReview() {
        // Find the active window scene to present the review prompt
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        AppStore.requestReview(in: scene)
    }
}
