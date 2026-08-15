//
//  PremiumManager.swift
//  Aura Health
//

import SwiftUI
import Combine
import RevenueCat

class PremiumManager: NSObject, ObservableObject, PurchasesDelegate, @unchecked Sendable {
    static let shared = PremiumManager()
    
    @Published var isPro: Bool = false {
        didSet {
            KeychainHelper.shared.saveBool(isPro, service: "com.jmrsoft.medicinas", account: "isPro")
            // Notificar a otras vistas que pudiesen depender de UserDefaults indirectamente
            UserDefaults.standard.set(isPro, forKey: "isProLegacyCache")
        }
    }
    
    @Published var availablePackages: [Package] = []
    @Published var isPurchasing: Bool = false
    @Published var hasAttemptedFetch: Bool = false
    
    override private init() {
        super.init()
        
        // Inicializar desde Keychain
        if let savedPro = KeychainHelper.shared.readBool(service: "com.jmrsoft.medicinas", account: "isPro") {
            self.isPro = savedPro
        } else if UserDefaults.standard.bool(forKey: "isPro") {
            // Migración de UserDefaults a Keychain
            self.isPro = true
            KeychainHelper.shared.saveBool(true, service: "com.jmrsoft.medicinas", account: "isPro")
            UserDefaults.standard.removeObject(forKey: "isPro")
        }
        
        // Defer the network call so it doesn't block app launch.
        // isPro is already cached in Keychain, so the UI shows immediately.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            if Purchases.isConfigured {
                Purchases.shared.delegate = self
            }
            self.checkSubscriptionStatus()
        }
    }
    
    // MARK: - PurchasesDelegate
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.hasActiveEntitlement(customerInfo) {
                self.isPro = true
            }
        }
    }
    
    func hasActiveEntitlement(_ info: CustomerInfo?) -> Bool {
        guard let info = info else { return false }
        
        #if DEBUG
        print("[RevenueCat] Active Entitlements: \(info.entitlements.active)")
        print("[RevenueCat] Active Subscriptions: \(info.activeSubscriptions)")
        print("[RevenueCat] All Purchased Product IDs: \(info.allPurchasedProductIdentifiers)")
        #endif
        
        // 1. Check entitlements
        if info.entitlements.active["pro"]?.isActive == true { return true }
        if info.entitlements.active["Pro"]?.isActive == true { return true }
        if info.entitlements.active["PRO"]?.isActive == true { return true }
        if info.entitlements.active["premium"]?.isActive == true { return true }
        if !info.entitlements.active.isEmpty { return true }
        
        // 2. Fallback: Check active subscriptions directly from Apple
        if !info.activeSubscriptions.isEmpty { return true }
        
        // 3. Fallback: Check all purchased product identifiers
        if !info.allPurchasedProductIdentifiers.isEmpty { return true }
        
        return false
    }
    
    func fetchOfferings() {
        guard Purchases.isConfigured else { return }
        Purchases.shared.getOfferings { [weak self] offerings, error in
            DispatchQueue.main.async {
                self?.hasAttemptedFetch = true
                if let packages = offerings?.current?.availablePackages {
                    self?.availablePackages = packages
                }
            }
        }
    }
    
    func purchase(package: Package) {
        guard Purchases.isConfigured else { return }
        isPurchasing = true
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                self?.isPurchasing = false
                if let self = self, self.hasActiveEntitlement(customerInfo) {
                    self.isPro = true
                }
            }
        }
    }
    
    func restorePurchases(completion: @escaping (Bool) -> Void = { _ in }) {
        guard Purchases.isConfigured else {
            completion(self.isPro)
            return
        }
        isPurchasing = true
        
        Purchases.shared.syncPurchases { [weak self] customerInfo, error in
            Purchases.shared.restorePurchases { [weak self] customerInfo, error in
                DispatchQueue.main.async {
                    self?.isPurchasing = false
                    if let self = self, self.hasActiveEntitlement(customerInfo) {
                        self.isPro = true
                        completion(true)
                    } else {
                        completion(self?.isPro ?? false)
                    }
                }
            }
        }
    }
    
    func checkSubscriptionStatus() {
        guard Purchases.isConfigured else { return }
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                if let self = self, self.hasActiveEntitlement(customerInfo) {
                    self.isPro = true
                }
            }
        }
    }
    
    func presentCodeRedemptionSheet() {
        guard Purchases.isConfigured else { return }
        Purchases.shared.presentCodeRedemptionSheet()
    }
}

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        
        if status == errSecDuplicateItem {
            let updateQuery = [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary
            
            let attributesToUpdate = [kSecValueData: data] as CFDictionary
            SecItemUpdate(updateQuery, attributesToUpdate)
        }
    }
    
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        return result as? Data
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary
        SecItemDelete(query)
    }
    
    func saveBool(_ value: Bool, service: String, account: String) {
        let valueStr = value ? "true" : "false"
        if let data = valueStr.data(using: .utf8) {
            save(data, service: service, account: account)
        }
    }
    
    func readBool(service: String, account: String) -> Bool? {
        if let data = read(service: service, account: account),
           let valueStr = String(data: data, encoding: .utf8) {
            return valueStr == "true"
        }
        return nil
    }
}
