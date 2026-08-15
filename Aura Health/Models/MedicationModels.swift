//
//  MedicationModels.swift
//  Aura Health
//

import Foundation

enum DoseForm: String, CaseIterable, Codable {
    case pill     = "Pastilla"
    case syrup    = "Jarabe"
    case ampoule  = "Ampolla"
    case pomade   = "Pomada"
    case cure     = "Cura"
    case other    = "Otro"

    var icon: String {
        switch self {
        case .pill:    return "capsule.fill"
        case .syrup:   return "drop.fill"
        case .ampoule: return "cross.vial.fill"
        case .pomade:  return "bandage.fill"
        case .cure:    return "cross.case.fill"
        case .other:   return "cross.fill"
        }
    }

    func unitSingular() -> String {
        switch self {
        case .pill:    return "pastilla"
        case .syrup:   return "cucharada"
        case .ampoule: return "ampolla"
        case .pomade:  return "aplicación"
        case .cure:    return "cura"
        case .other:   return "toma"
        }
    }

    func unitPlural() -> String {
        switch self {
        case .pill:    return "pastillas"
        case .syrup:   return "cucharadas"
        case .ampoule: return "ampollas"
        case .pomade:  return "aplicaciones"
        case .cure:    return "curas"
        case .other:   return "tomas"
        }
    }

    /// Whether half-unit increments make sense for this form
    var supportsHalf: Bool {
        switch self {
        case .pill, .syrup, .other, .pomade: return true
        case .ampoule, .cure:                return false
        }
    }
}

enum DoseAmount: String, CaseIterable, Codable {
    case half         = "½"
    case one          = "1"
    case oneAndHalf   = "1½"
    case two          = "2"
    case twoAndHalf   = "2½"
    case three        = "3"
    case threeAndHalf = "3½"
    case four         = "4"

    var numericValue: Double {
        switch self {
        case .half:         return 0.5
        case .one:          return 1.0
        case .oneAndHalf:   return 1.5
        case .two:          return 2.0
        case .twoAndHalf:   return 2.5
        case .three:        return 3.0
        case .threeAndHalf: return 3.5
        case .four:         return 4.0
        }
    }

    /// Integer part (0 for .half, 1 for .one and .oneAndHalf, etc.)
    var wholePart: Int {
        switch self {
        case .half:                    return 0
        case .one, .oneAndHalf:        return 1
        case .two, .twoAndHalf:        return 2
        case .three, .threeAndHalf:    return 3
        case .four:                    return 4
        }
    }

    var hasHalf: Bool { numericValue != Double(wholePart) }

    /// Build a DoseAmount from whole + half parts
    static func make(whole: Int, half: Bool) -> DoseAmount {
        switch (whole, half) {
        case (0, _):     return .half
        case (1, false): return .one
        case (1, true):  return .oneAndHalf
        case (2, false): return .two
        case (2, true):  return .twoAndHalf
        case (3, false): return .three
        case (3, true):  return .threeAndHalf
        default:         return .four        // 4 (no half for 4)
        }
    }

    func displayText(for form: DoseForm) -> String {
        let isPlural = numericValue > 1
        let unit = isPlural ? form.unitPlural() : form.unitSingular()
        return "\(rawValue) \(unit)"
    }
}

struct UserProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var avatarColor: String
    var isMain: Bool
    var medicalConditions: [String]
    var lastFreeReportDate: Date?
    
    init(id: UUID = UUID(), name: String, avatarColor: String, isMain: Bool = false, medicalConditions: [String] = [], lastFreeReportDate: Date? = nil) {
        self.id = id
        self.name = name
        self.avatarColor = avatarColor
        self.isMain = isMain
        self.medicalConditions = medicalConditions
        self.lastFreeReportDate = lastFreeReportDate
    }
}

struct MedicationInventory: Codable {
    var medicationName: String
    var currentStock: Double
    var lowStockThreshold: Double
    var profileId: UUID?
}

struct MedicationDose: Identifiable, Codable {
    var id: UUID
    var profileId: UUID?
    var medicationName: String
    var amount: DoseAmount
    var milligrams: Int?
    var form: DoseForm
    var scheduledTime: Date
    var isTaken: Bool

    var doseDescription: String {
        var parts = [medicationName]
        if let mg = milligrams { parts.append("\(mg) mg") }
        parts.append(amount.displayText(for: form))
        return parts.joined(separator: " · ")
    }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: scheduledTime)
    }

    init(id: UUID = UUID(),
         profileId: UUID? = nil,
         medicationName: String,
         amount: DoseAmount,
         milligrams: Int?,
         form: DoseForm,
         scheduledTime: Date,
         isTaken: Bool = false) {
        self.id = id
        self.profileId = profileId
        self.medicationName = medicationName
        self.amount = amount
        self.milligrams = milligrams
        self.form = form
        self.scheduledTime = scheduledTime
        self.isTaken = isTaken
    }
}

struct AppointmentAttachment: Identifiable, Codable, Equatable {
    var id: UUID
    var originalName: String
    var fileType: String // "image", "pdf", etc.
    var relativePath: String // Relative to Documents directory to keep sandbox paths robust
}

struct MedicalAppointment: Identifiable, Codable {
    var id: UUID
    var profileId: UUID?
    var title: String
    var date: Date
    var specialty: String?
    var notes: String?
    var attachments: [AppointmentAttachment]?

    var displayText: String {
        let datePart = date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
        if let specialty { return "\(title) - \(datePart) (\(specialty))" }
        return "\(title) - \(datePart)"
    }

    init(id: UUID = UUID(), profileId: UUID? = nil, title: String, date: Date, specialty: String? = nil, notes: String? = nil, attachments: [AppointmentAttachment]? = nil) {
        self.id = id
        self.profileId = profileId
        self.title = title
        self.date = date
        self.specialty = specialty
        self.notes = notes
        self.attachments = attachments
    }
}

struct HealthMetric: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var profileId: UUID
    var type: MetricType
    var value: Double
    var date: Date
    var unit: String
    
    enum MetricType: String, Codable, CaseIterable {
        case weight = "Peso"
        case heartRate = "Ritmo Cardíaco"
        
        case glucose = "Glucosa"
        case bloodPressureSystolic = "Presión Sistólica"
        case bloodPressureDiastolic = "Presión Diastólica"
        
        // Nuevas métricas avanzadas
        case cholesterol = "Colesterol"
        case bloodOxygen = "Oxígeno en Sangre"
        case temperature = "Temperatura"
        case hba1c = "HbA1c"
        case painLevel = "Nivel de Dolor"
        
        var isPremium: Bool {
            switch self {
            case .weight, .heartRate:
                return false
            default:
                return true
            }
        }
        
        var defaultUnit: String {
            switch self {
            case .weight: return "kg"
            case .heartRate: return "bpm"
            case .glucose, .cholesterol: return "mg/dL"
            case .bloodPressureSystolic, .bloodPressureDiastolic: return "mmHg"
            case .bloodOxygen, .hba1c: return "%"
            case .temperature: return "°C"
            case .painLevel: return "/10"
            }
        }
    }
}
