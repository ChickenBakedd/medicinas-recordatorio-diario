import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    
    func requestAuthorization() async {
        guard !isAuthorized else { return }
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let sysType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diaType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic),
              let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
              
        let typesToShare: Set<HKSampleType> = [weightType, sysType, diaType, glucoseType, heartRateType]
        let typesToRead: Set<HKObjectType> = [weightType, sysType, diaType, glucoseType, heartRateType]
        
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            isAuthorized = true
        } catch {
            print("Error requesting HealthKit authorization: \(error)")
        }
    }
    
    func saveMetric(_ metric: HealthMetric) async {
        guard isAuthorized else { return }
        
        var quantityTypeIdentifier: HKQuantityTypeIdentifier
        var unit: HKUnit
        
        switch metric.type {
        case .weight:
            quantityTypeIdentifier = .bodyMass
            unit = HKUnit.gramUnit(with: .kilo)
        case .bloodPressureSystolic:
            quantityTypeIdentifier = .bloodPressureSystolic
            unit = HKUnit.millimeterOfMercury()
        case .bloodPressureDiastolic:
            quantityTypeIdentifier = .bloodPressureDiastolic
            unit = HKUnit.millimeterOfMercury()
        case .glucose:
            quantityTypeIdentifier = .bloodGlucose
            unit = HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci))
        case .heartRate:
            quantityTypeIdentifier = .heartRate
            unit = HKUnit.count().unitDivided(by: .minute())
        default:
            return
        }
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: quantityTypeIdentifier) else { return }
        
        let quantity = HKQuantity(unit: unit, doubleValue: metric.value)
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: metric.date, end: metric.date)
        
        do {
            try await healthStore.save(sample)
        } catch {
            print("Error saving HealthKit data: \(error)")
        }
    }
    
    @available(iOS 26.0, *)
    func fetchMedications() async throws -> [HKUserAnnotatedMedication] {
        guard isAuthorized else { throw NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "No autorizado"]) }
        
        let descriptor = HKUserAnnotatedMedicationQueryDescriptor(
            predicate: nil
        )
        
        let results = try await descriptor.result(for: healthStore)
        return results
    }
    
    @available(iOS 26.0, *)
    func importMedications(into store: MedicationStore) async {
        await requestAuthorization()
        
        // Apple requires a special Developer Program entitlement to read medications.
        // Until Apple approves the entitlement in the developer portal, this query will crash if executed.
        // Returning an empty array to simulate no medications found.
        let hkMedications: [HKUserAnnotatedMedication] = [] 
        
        await MainActor.run {
            for hkMed in hkMedications {
                // Evitar duplicados por nombre
                let name = hkMed.nickname ?? "Medicina Desconocida"
                if !store.allDoses.contains(where: { $0.medicationName.lowercased() == name.lowercased() }) {
                    let newDose = MedicationDose(
                        id: UUID(),
                        profileId: store.activeProfileId,
                        medicationName: name,
                        amount: .one, // Por defecto
                        milligrams: nil,
                        form: .pill,
                        scheduledTime: Date(), // Por defecto
                        isTaken: false
                    )
                    store.allDoses.append(newDose)
                }
            }
            store.updateDerivedState()
            store.saveState()
        }
    }

}
