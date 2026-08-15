import SwiftUI
import AVFoundation
import Vision
import Combine

// MARK: - Pro Glass Camera OCR View

struct ProGlassCameraOCRView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let onResult: (OCRMedicationResult) -> Void

    @StateObject private var camera = CameraModel()
    @State private var isAnalyzing = false
    @State private var showResult = false
    @State private var ocrResult: OCRMedicationResult? = nil
    @State private var recognizedLines: [String] = []
    @State private var flashOn = false

    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    
    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)
    
    private var tint: Color {
        isGraphite ? gold : isDark ? Color.green : Color.blue
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.permissionDenied {
                permissionDeniedView
            } else {
                // Camera preview
                CameraPreviewLayer(session: camera.session)
                    .ignoresSafeArea()

                // Overlay UI
                VStack {
                    // Top bar
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        Spacer()
                        Button {
                            flashOn.toggle()
                            camera.toggleFlash(on: flashOn)
                        } label: {
                            Image(systemName: flashOn ? "bolt.fill" : "bolt.slash")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(flashOn ? tint : .white)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()

                    // Viewfinder guide
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(tint.opacity(0.8), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.2))
                        )
                        .frame(height: 160)
                        .padding(.horizontal, 40)
                        .overlay(
                            Text("Apunta al nombre y dosis del medicamento")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(.top, 190)
                        )

                    Spacer()

                    // Capture button
                    Button {
                        captureAndAnalyze()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 84, height: 84)
                            
                            Circle()
                                .stroke(tint, lineWidth: 3)
                                .frame(width: 76, height: 76)
                            
                            Circle()
                                .fill(tint.opacity(0.8))
                                .frame(width: 66, height: 66)
                            
                            Image(systemName: "text.viewfinder")
                                .font(.title)
                                .foregroundStyle(.white)
                            
                            if isAnalyzing {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.5)
                            }
                        }
                    }
                    .disabled(isAnalyzing)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear { camera.setup() }
        .onDisappear { camera.stop() }
        .sheet(isPresented: $showResult) {
            if let result = ocrResult {
                ProGlassOCRResultView(
                    result: result,
                    lines: recognizedLines,
                    onConfirm: { confirmed in
                        dismiss()
                        onResult(confirmed)
                    },
                    onRetry: {
                        showResult = false
                        ocrResult = nil
                    }
                )
            }
        }
    }

    private func captureAndAnalyze() {
        isAnalyzing = true
        camera.capturePhoto { image in
            guard let image else {
                isAnalyzing = false
                return
            }
            analyzeImage(image)
        }
    }

    private func analyzeImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            isAnalyzing = false
            return
        }

        let request = VNRecognizeTextRequest { req, _ in
            DispatchQueue.main.async {
                isAnalyzing = false
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                recognizedLines = lines
                ocrResult = parseOCRLines(lines)
                showResult = true
            }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["es", "en"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    private func parseOCRLines(_ lines: [String]) -> OCRMedicationResult {
        let mgPattern = /(\d+)\s*[mM][gG]/
        var detectedMg: Int? = nil
        var nameCandidate = ""

        for line in lines {
            if let match = line.firstMatch(of: mgPattern) {
                detectedMg = Int(match.1)
            }
        }

        let candidate = lines
            .filter { line in
                let letters = line.filter { $0.isLetter || $0.isWhitespace }
                return letters.count > 4 && !line.contains("mg") && !line.contains("MG")
            }
            .max(by: { $0.count < $1.count }) ?? lines.first ?? ""

        nameCandidate = candidate
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: " ")
            .capitalized

        return OCRMedicationResult(name: nameCandidate, milligrams: detectedMg)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.6))
            Text("Acceso a la cámara denegado")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Text("Ve a Ajustes > Medicinas > Cámara para activarla")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Capsule().fill(tint))
        }
    }
}

// MARK: - Pro Glass OCR Result View

struct ProGlassOCRResultView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State var result: OCRMedicationResult
    let lines: [String]
    let onConfirm: (OCRMedicationResult) -> Void
    let onRetry: () -> Void

    @State private var mgText: String = ""
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    
    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)
    
    private var tint: Color {
        isGraphite ? gold : isDark ? Color.green : Color.blue
    }

    var body: some View {
        NavigationStack {
            ZStack {
                glassBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Success icon
                        ZStack {
                            Circle()
                                .fill(tint.opacity(0.15))
                                .frame(width: 84, height: 84)
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 34))
                                .foregroundStyle(tint)
                        }
                        .padding(.top, 16)

                        Text("¡Texto Detectado!")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(isGraphite ? .white : .primary)

                        // Editable Fields
                        VStack(spacing: 20) {
                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Medicamento")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.secondary)
                                TextField("Nombre", text: $result.name)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(isGraphite ? Color.white.opacity(0.05) : Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.7))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .foregroundStyle(isGraphite ? .white : .primary)
                            }
                            
                            // Dosis
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Dosis (mg)")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.secondary)
                                TextField("Ej. 500", text: $mgText)
                                    .keyboardType(.numberPad)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(isGraphite ? Color.white.opacity(0.05) : Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.7))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .foregroundStyle(isGraphite ? .white : .primary)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Action Buttons
                        VStack(spacing: 16) {
                            Button {
                                if let val = Int(mgText) {
                                    result.milligrams = val
                                }
                                onConfirm(result)
                            } label: {
                                Text("Usar estos datos")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Capsule().fill(tint))
                                    .foregroundStyle(.white)
                            }
                            
                            Button {
                                onRetry()
                            } label: {
                                Text("Reintentar escaneo")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        Capsule()
                                            .stroke(tint, lineWidth: 2)
                                    )
                                    .foregroundStyle(tint)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        
                        // Raw lines info
                        if !lines.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Texto detectado en la imagen:")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(lines, id: \.self) { line in
                                        Text(line)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(isGraphite ? Color.white.opacity(0.05) : Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.7))
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Resultados OCR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(isGraphite ? .white : .primary)
                }
            }
        }
        .onAppear {
            if let mg = result.milligrams {
                mgText = "\(mg)"
            }
        }
    }
    
    private var glassBackground: some View {
        ZStack {
            if isGraphite {
                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            } else if colorScheme == .dark {
                Color.black.ignoresSafeArea()
                Circle().fill(Color.green.opacity(0.15)).frame(width: 300, height: 300).blur(radius: 80).offset(x: -100, y: -200)
                Circle().fill(Color.mint.opacity(0.15)).frame(width: 300, height: 300).blur(radius: 80).offset(x: 100, y: 200)
            } else {
                Color.white.ignoresSafeArea()
                Circle().fill(Color.blue.opacity(0.12)).frame(width: 300, height: 300).blur(radius: 60).offset(x: -150, y: -200)
                Circle().fill(Color.purple.opacity(0.12)).frame(width: 350, height: 350).blur(radius: 80).offset(x: 150, y: 150)
            }
        }
    }
}
