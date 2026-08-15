//
//  PDFGenerator.swift
//  Aura Health
//

import SwiftUI

@MainActor
class PDFGenerator {
    static func generateMedicalReport(store: MedicationStore, isAdvanced: Bool = true) -> URL? {
        let page1 = MedicalReportView(store: store)
        let page2 = MedicalReportVitalsView(store: store)
        
        let renderer1 = ImageRenderer(content: page1)
        let renderer2 = ImageRenderer(content: page2)
        
        let safeProfileName = (store.activeProfile?.name ?? "Paciente")
            .replacingOccurrences(of: " ", with: "_")
            .folding(options: .diacriticInsensitive, locale: .current)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Informe_Medico_\(safeProfileName).pdf")
        
        renderer1.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return
            }
            
            // Page 1
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            
            // Page 2 (Only if Advanced)
            if isAdvanced {
                renderer2.render { size2, context2 in
                    pdf.beginPDFPage(nil)
                    context2(pdf)
                    pdf.endPDFPage()
                }
            }
            
            pdf.closePDF()
        }
        
        return url
    }
}
