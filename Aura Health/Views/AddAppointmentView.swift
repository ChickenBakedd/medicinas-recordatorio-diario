//
//  AddAppointmentView.swift
//  Aura Health
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AddAppointmentView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: MedicationStore
    @State private var vm: AddAppointmentViewModel

    init(store: MedicationStore, existingAppointment: MedicalAppointment? = nil) {
        self.store = store
        _vm = State(initialValue: AddAppointmentViewModel(store: store, existingAppointment: existingAppointment))
    }

    private let tint = Color(red: 0.75, green: 0.45, blue: 0.32)

    private var isCustomSpecialty: Bool {
        vm.isCustomSpecialty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()
                ScrollView {
                    VStack(spacing: 16) {

                        // Title field
                        formField(label: "Médico o nombre de la cita") {
                            TextField("Ej: Dra. García", text: $vm.title)
                                .font(.system(.title3, design: .rounded))
                                .autocorrectionDisabled()
                        }

                        // Specialty
                        formField(label: "Especialidad — opcional") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    TextField("Ej: Cardiología", text: $vm.specialty)
                                        .font(.system(.title3, design: .rounded))
                                        .autocorrectionDisabled()
                                    
                                    if isCustomSpecialty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "pencil")
                                                .font(.caption2)
                                            Text("Propia")
                                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                        }
                                        .foregroundStyle(tint)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(tint.opacity(0.12)))
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }

                                // Quick chips
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                                    ForEach(vm.quickSpecialties, id: \.self) { s in
                                        Button {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                                vm.specialty = s
                                            }
                                        } label: {
                                            Text(s)
                                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(vm.specialty == s ? tint.opacity(0.15) : theme.chipFill)
                                                        .overlay(Capsule().stroke(vm.specialty == s ? tint.opacity(0.4) : Color.clear, lineWidth: 1))
                                                )
                                                .foregroundStyle(vm.specialty == s ? tint : theme.textPrimary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Notes
                        formField(label: "Notas o instrucciones") {
                            TextField("Ej: Llevar analítica de sangre", text: $vm.notes, axis: .vertical)
                                .font(.system(.title3, design: .rounded))
                                .lineLimit(3...5)
                        }

                        // Attachments
                        formField(label: "Documentos") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    // Add Photo
                                    PhotosPicker(selection: $vm.selectedItem, matching: .images) {
                                        HStack {
                                            Image(systemName: "photo.badge.plus")
                                            Text("Foto")
                                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.1)))
                                        .foregroundStyle(tint)
                                    }
                                    .buttonStyle(.plain)

                                    // Add File
                                    Button {
                                        vm.isFileImporterPresented = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "doc.badge.plus")
                                            Text("Archivo")
                                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.1)))
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
                                        HStack(spacing: 12) {
                                            ForEach(vm.attachments) { attachment in
                                                AttachmentBubble(attachment: attachment) {
                                                    withAnimation {
                                                        vm.deleteAttachment(attachment)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                } else {
                                    Text("No hay archivos adjuntos (informes, recetas, radiografías...)")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(theme.textMuted)
                                        .padding(.top, 4)
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
                        }

                        // Preview
                        if !vm.title.isEmpty {
                            previewCard
                        }

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(vm.isEditing ? "Editar Cita" : "Nueva Cita")
            .navigationBarTitleDisplayMode(.inline)
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
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(vm.canSave ? tint : theme.textMuted)
                    .disabled(!vm.canSave)
                }
            }
            .applyThemeMode()
        }
    }

    // MARK: - Form helper

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textMuted)
                .textCase(.uppercase)
            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.barFill)
                        .shadow(color: theme.softShadow, radius: 6, y: 2)
                )
        }
    }

    // MARK: - Preview card

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vista previa")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textMuted)
                .textCase(.uppercase)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                    let specPart = vm.specialty.trimmingCharacters(in: .whitespaces).isEmpty ? "" : " · \(vm.specialty)"
                    Text("\(vm.date.formatted(.dateTime.day().month(.abbreviated)))\(specPart)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                Text(vm.date.formatted(.dateTime.hour().minute()))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(tint)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.barFill))
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
        }
    }
}

// MARK: - Helper Views

struct AttachmentBubble: View {
    @Environment(\.appTheme) private var theme
    let attachment: AppointmentAttachment
    let onDelete: () -> Void
    @State private var showViewer = false

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
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: attachment.fileType == "pdf" ? "doc.richtext.fill" : "doc.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(red: 0.75, green: 0.45, blue: 0.32))
                        Text(attachment.originalName)
                            .font(.system(size: 8, design: .rounded))
                            .lineLimit(1)
                            .frame(width: 50)
                            .foregroundStyle(theme.textSecondary)
                    }
                    .frame(width: 60, height: 60)
                    .background(theme.barFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.trackGray.opacity(0.3), lineWidth: 1))
                }
            }
            .frame(width: 60, height: 60)
            .contentShape(Rectangle())
            .onTapGesture {
                showViewer = true
            }

            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.red, .white)
            }
            .offset(x: 6, y: -6)
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showViewer) {
            AttachmentViewer(attachment: attachment)
                .environment(\.appTheme, theme)
        }
    }
}

struct AttachmentViewer: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let attachment: AppointmentAttachment

    private var uiImage: UIImage? {
        guard attachment.fileType == "image",
              let url = AttachmentManager.shared.getFullAttachmentURL(for: attachment),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private var fileURL: URL? {
        AttachmentManager.shared.getFullAttachmentURL(for: attachment)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                } else if let fileURL {
                    VStack(spacing: 20) {
                        Image(systemName: attachment.fileType == "pdf" ? "doc.richtext.fill" : "doc.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                        Text(attachment.originalName)
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                        ShareLink(item: fileURL) {
                            Label("Abrir / Compartir Documento", systemImage: "square.and.arrow.up")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15)))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .navigationTitle(attachment.originalName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hecho") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddAppointmentView(store: MedicationStore())
}
