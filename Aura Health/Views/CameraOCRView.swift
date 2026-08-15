//
//  CameraOCRView.swift
//  Aura Health
//

import SwiftUI
import AVFoundation
import Vision
import Combine

// MARK: - Result model

struct OCRMedicationResult {
    var name: String
    var milligrams: Int?
}

// MARK: - Camera OCR View

struct CameraOCRView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let onResult: (OCRMedicationResult) -> Void

    @StateObject private var camera = CameraModel()
    @State private var isAnalyzing = false
    @State private var showResult = false
    @State private var ocrResult: OCRMedicationResult? = nil
    @State private var recognizedLines: [String] = []
    @State private var flashOn = false

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
                                .background(Circle().fill(Color.black.opacity(0.4)))
                        }
                        Spacer()
                        Button {
                            flashOn.toggle()
                            camera.toggleFlash(on: flashOn)
                        } label: {
                            Image(systemName: flashOn ? "bolt.fill" : "bolt.slash")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(flashOn ? .yellow : .white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.4)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()

                    // Viewfinder guide
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                        .frame(height: 160)
                        .padding(.horizontal, 40)
                        .overlay(
                            Text("Apunta al nombre y dosis del medicamento")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.top, 170)
                        )

                    Spacer()

                    // Capture button
                    Button {
                        captureAndAnalyze()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 72, height: 72)
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 4)
                                .frame(width: 84, height: 84)
                            if isAnalyzing {
                                ProgressView()
                                    .tint(theme.accent)
                                    .scaleEffect(1.3)
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
                OCRResultView(
                    result: result,
                    lines: recognizedLines,
                    onConfirm: { confirmed in
                        showResult = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                            onResult(confirmed)
                        }
                    },
                    onRetry: {
                        showResult = false
                        ocrResult = nil
                    }
                )
                .environment(\.appTheme, theme)
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
        // Find mg value: match patterns like "600mg", "600 mg", "20MG" etc.
        let mgPattern = /(\d+)\s*([mM][gG]|[mM][lL]|[gG])/
        var detectedMg: Int? = nil
        var nameCandidate = ""

        for line in lines {
            if let match = line.firstMatch(of: mgPattern) {
                detectedMg = Int(match.1)
            }
        }

        // Name heuristic: longest line that is mostly alphabetic and not too short
        let candidate = lines
            .filter { line in
                let letters = line.filter { $0.isLetter || $0.isWhitespace }
                let lower = line.lowercased()
                return letters.count > 4 && !lower.contains("mg") && !lower.contains("ml") && !lower.hasSuffix("g")
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
            .background(Capsule().fill(theme.accent))
        }
    }
}

// MARK: - OCR Result View

struct OCRResultView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State var result: OCRMedicationResult
    let lines: [String]
    let onConfirm: (OCRMedicationResult) -> Void
    let onRetry: () -> Void

    @State private var mgText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Success icon
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 34))
                                .foregroundStyle(theme.accent)
                        }
                        .padding(.top, 8)

                        Text("Texto reconocido")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.textPrimary)

                        // Editable fields
                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Nombre del medicamento")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(theme.textMuted)
                                TextField("Nombre", text: $result.name)
                                    .font(.system(.body, design: .rounded))
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.8)))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Dosis (mg)")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(theme.textMuted)
                                TextField("Ej: 600", text: $mgText)
                                    .keyboardType(.numberPad)
                                    .font(.system(.body, design: .rounded))
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.8)))
                                    .onChange(of: mgText) { _, new in
                                        result.milligrams = Int(new)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Raw lines detected
                        if !lines.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Texto completo detectado")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(theme.textMuted)
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(lines.prefix(8), id: \.self) { line in
                                        Text("· \(line)")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.5)))
                            }
                            .padding(.horizontal, 20)
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button {
                                onConfirm(result)
                            } label: {
                                Text("Usar este medicamento")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(
                                        LinearGradient(colors: [theme.accent.opacity(0.85), theme.accent],
                                                       startPoint: .top, endPoint: .bottom)))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)

                            Button {
                                onRetry()
                            } label: {
                                Text("Volver a escanear")
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.6)))
                                    .foregroundStyle(theme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .onAppear {
            mgText = result.milligrams.map { "\($0)" } ?? ""
        }
    }
}

// MARK: - Camera Model

final class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var permissionDenied = false
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?

    func setup() {
        Task {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                configureSession()
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted { configureSession() } else {
                    DispatchQueue.main.async { self.permissionDenied = true }
                }
            default:
                DispatchQueue.main.async { self.permissionDenied = true }
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stop() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }

    func toggleFlash(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let image: UIImage? = photo.fileDataRepresentation().flatMap { UIImage(data: $0) }
        DispatchQueue.main.async {
            self.captureCompletion?(image)
            self.captureCompletion = nil
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
