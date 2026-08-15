import SwiftUI

struct HealthTip: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let colorName: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, icon
        case colorName = "color"
    }
    
    var color: Color {
        switch colorName {
        case "blue": return .blue
        case "indigo": return .indigo
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "cyan": return .cyan
        case "teal": return .teal
        case "yellow": return .yellow
        case "brown": return .brown
        case "mint": return .mint
        case "pink": return .pink
        case "gray": return .gray
        default: return .blue
        }
    }
}

extension HealthTip {
    static let allTips: [HealthTip] = loadTips()
    
    static func loadTips() -> [HealthTip] {
        guard let url = Bundle.main.url(forResource: "health_tips", withExtension: "json") else {
            print("Failed to find health_tips.json in bundle.")
            return fallbackTips
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let tips = try decoder.decode([HealthTip].self, from: data)
            return tips
        } catch {
            print("Failed to decode health_tips.json: \(error)")
            return fallbackTips
        }
    }
    
    private static var fallbackTips: [HealthTip] {
        [
            HealthTip(id: UUID(), title: "Salud", description: "Beber agua ayuda a metabolizar mejor los medicamentos.", icon: "drop.fill", colorName: "blue")
        ]
    }
}
