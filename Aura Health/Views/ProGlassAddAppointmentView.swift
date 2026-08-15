//
//  ProGlassAddAppointmentView.swift
//  Aura Health
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ProGlassAddAppointmentView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @Bindable var store: MedicationStore
    @State private var vm: AddAppointmentViewModel

    init(store: MedicationStore, existingAppointment: MedicalAppointment? = nil) {
        self.store = store
        _vm = State(initialValue: AddAppointmentViewModel(store: store, existingAppointment: existingAppointment))
    }

    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)

    private var tint: Color {
        isGraphite ? gold : isDark ? Color.green : Color.orange
    }

    private var isCustomSpecialty: Bool {
        vm.isCustomSpecialty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                glassBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // Title field
                        formField(label: "Médico o nombre de la cita") {
                            TextField("Ej: Dra. García", text: $vm.title)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .autocorrectionDisabled()
                        }

                        // Specialty
                        formField(label: "Especialidad — opcional") {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "stethoscope")
                                        .foregroundStyle(tint)
                                        .font(.title3)
                                    
                                    TextField("Ej: Cardiología", text: $vm.specialty)
                                        .font(.system(.title3, design: .rounded).weight(.semibold))
                                        .autocorrectionDisabled()
                                    
                                    if isCustomSpecialty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "pencil")
                                                .font(.caption2)
                                            Text("Propia")
                                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                        }
                                        .foregroundStyle(tint)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(tint.opacity(0.15)))
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }

                                // Quick chips
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(vm.quickSpecialties, id: \.self) { s in
                                            Button {
                                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                                    vm.specialty = s
                                                }
                                            } label: {
                                                Text(s)
                                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(
                                                        Capsule()
                                                            .fill(vm.specialty == s ? tint.opacity(0.15) : (isGraphite ? Color.white.opacity(0.05) : Color.gray.opacity(0.1)))
                                                            .overlay(Capsule().stroke(vm.specialty == s ? tint.opacity(0.4) : Color.clear, lineWidth: 1))
                                                    )
                                                    .foregroundStyle(vm.specialty == s ? tint : Color.secondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // Notes
                        formField(label: "Notas o instrucciones") {
                            TextField("Ej: Llevar analítica, venir en ayunas...", text: $vm.notes, axis: .vertical)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .lineLimit(3...5)
                        }

                        // Attachments
                        formField(label: "Documentos") {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    // Add Photo
                                    PhotosPicker(selection: $vm.selectedItem, matching: .images) {
                                        HStack {
                                            Image(systemName: "camera.fill")
                                            Text("Foto")
                                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .background(Capsule().fill(tint.opacity(0.15)))
                                        .foregroundStyle(tint)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // Add File
                                    Button {
                                        vm.isFileImporterPresented = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "doc.fill")
                                            Text("Archivo")
                                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .background(Capsule().fill(tint.opacity(0.15)))
                                        .foregroundStyle(tint)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .fileImporter(
                                    isPresented: $vm.isFileImporterPresented,
                                    allowedContentTypes: [.pdf, .image, .item],
                                    allowsMultipleSelection: false
                                ) { result in
                                    switch result {
                                    case .success(let urls):
                                        if let url = urls.first {
                                            withAnimation {
                                                vm.handleFileImport(url)
                                            }
                                        }
                                    case .failure(let error):
                                        print("Error al importar archivo: \(error)")
                                    }
                                }

                                // Attachments List
                                if !vm.attachments.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(vm.attachments) { attachment in
                                                AttachmentBubblePro(attachment: attachment) {
                                                    withAnimation {
                                                        vm.deleteAttachment(attachment)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                        }

                        // Date & time
                        formField(label: "Fecha y hora") {
                            DatePicker("", selection: $vm.date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .tint(tint)
                                .environment(\.locale, Locale(identifier: "es_ES"))
                                .colorScheme(isDark || isGraphite ? .dark : .light)
                        }

                        // Preview
                        if !vm.title.isEmpty {
                            previewCard
                        }

                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle(vm.isEditing ? "Editar Cita" : "Nueva Cita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(tint)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(vm.isEditing ? "Guardar" : "Añadir") {
                        vm.saveAppointment()
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(vm.canSave ? tint : (colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)))
                    .disabled(!vm.canSave)
                }
            }
            .applyThemeMode()
        }
        .onAppear { vm.loadExistingIfNeeded() }
    }
    
    private var glassBackground: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
            
            Circle()
                .fill(Color.orange.opacity(0.12))
                .frame(width: 350, height: 350)
                .blur(radius: 60)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(Color.pink.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 150, y: 300)
        }
        .ignoresSafeArea()
    }

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Color.gray)
                .textCase(.uppercase)

            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke((colorScheme == .dark ? Color.black : Color.white).opacity(0.5), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.03), radius: 8, y: 2)
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vista previa")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                    let specPart = vm.specialty.trimmingCharacters(in: .whitespaces).isEmpty ? "" : " · \(vm.specialty)"
                    Text("\(vm.date.formatted(.dateTime.day().month(.abbreviated)))\(specPart)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(vm.date.formatted(.dateTime.hour().minute()))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(tint)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : Color.white.opacity(0.5), lineWidth: 1))
            )
        }
    }
}

// MARK: - Helper Views

struct AttachmentBubblePro: View {
    let attachment: AppointmentAttachment
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @State private var showViewer = false

    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)

    private var tint: Color {
        isGraphite ? gold : isDark ? Color.green : Color.orange
    }

    private var uiImage: UIImage? {
        guard attachment.fileType == "image",
              let url = AttachmentManager.shared.getFullAttachmentURL(for: attachment),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: attachment.fileType == "pdf" ? "doc.richtext.fill" : "doc.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(tint)
                        Text(attachment.originalName)
                            .font(.system(size: 9, design: .rounded).weight(.medium))
                            .lineLimit(1)
                            .frame(width: 60)
                            .foregroundStyle(Color.primary.opacity(0.7))
                    }
                    .frame(width: 70, height: 70)
                    .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : (colorScheme == .dark ? Color.black : Color.white).opacity(0.5), lineWidth: 1))
                }
            }
            .frame(width: 70, height: 70)
            .contentShape(Rectangle())
            .onTapGesture {
                showViewer = true
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.gray, Color.white)
                    .shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
        .padding([.top, .trailing], 6)
        .sheet(isPresented: $showViewer) {
            AttachmentViewer(attachment: attachment)
        }
    }
}
