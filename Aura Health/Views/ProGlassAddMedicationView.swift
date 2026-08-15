//
//  ProGlassAddMedicationView.swift
//  Aura Health
//

import SwiftUI

struct ProGlassAddMedicationView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @Bindable var store: MedicationStore
    @State private var vm: AddMedicationViewModel
    
    @State private var showingPaywall = false
    
    private var isGraphite: Bool { appThemeMode == "graphite" }
    private var isDark: Bool { appThemeMode == "pureBlack" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)

    private var tint: Color {
        isGraphite ? gold : isDark ? Color.green : Color.blue
    }

    init(store: MedicationStore, existingDose: MedicationDose? = nil) {
        self.store = store
        _vm = State(initialValue: AddMedicationViewModel(store: store, existingDose: existingDose))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                glassBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Free Tier Indicator
                        if !vm.isEditing && !PremiumManager.shared.isPro {
                            HStack(spacing: 8) {
                                Image(systemName: "pills.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(tint)
                                Text("Medicamentos gratuitos: \(store.distinctMedicationNames.count)/3")
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundStyle(Color.secondary)
                                Spacer()
                                Button {
                                    showingPaywall = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 10))
                                        Text("Ilimitados")
                                            .font(.system(.caption2, design: .rounded).weight(.bold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.orange))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isGraphite ? Color.white.opacity(0.06) : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Preview card
                        if !vm.name.isEmpty {
                            previewCard
                        }

                        // Input mode selector
                        if !vm.isEditing {
                            inputModeSelector
                        }

                        // Form fields
                        formSection

                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle(vm.isEditing ? "Editar Medicamento" : "Añadir Medicamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(tint)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(vm.isEditing ? "Guardar" : "Añadir") {
                        if !vm.isEditing && !store.canAddMoreMedications(named: vm.name) {
                            showingPaywall = true
                        } else {
                            vm.saveDose()
                            dismiss()
                        }
                    }
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(vm.canSave ? tint : (colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)))
                    .disabled(!vm.canSave)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .fullScreenCover(isPresented: $vm.showCamera) {
                ProGlassCameraOCRView { result in
                    vm.handleScanResult(result)
                }
                .environment(\.appTheme, theme)
            }
            .applyThemeMode()
        }
        .onAppear { vm.loadExistingIfNeeded() }
    }

    private var glassBackground: some View {
        ZStack {
            if isGraphite {
                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            } else {
                (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 350, height: 350)
                    .blur(radius: 60)
                    .offset(x: -150, y: -200)
                
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 150, y: 300)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Input Mode Selector

    private var inputModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(AddMedicationInputMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        vm.inputMode = mode
                        if mode == .camera { vm.showCamera = true }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode == .manual ? "pencil" : "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(mode == .manual ? "A mano" : "Con cámara")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        vm.inputMode == mode
                        ? LinearGradient(colors: isGraphite ? [gold.opacity(0.8), gold.opacity(0.6)] : isDark ? [Color.green, Color.mint] : [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundStyle(vm.inputMode == mode ? Color.white : Color.gray)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : Color.white.opacity(0.5), lineWidth: 1))
        .shadow(color: Color.black.opacity(isGraphite ? 0.3 : 0.05), radius: 10, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: vm.inputMode)
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 20) {
            // Name
            formField(label: "Nombre del medicamento") {
                TextField("Ej: Ibuprofeno", text: $vm.name)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .autocorrectionDisabled()
            }

            // Mg
            formField(label: "Dosis (mg) — opcional") {
                TextField("Ej: 600", text: $vm.mgText)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .keyboardType(.numberPad)
            }

            // Forma
            formField(label: "Forma") {
                Picker("", selection: $vm.selectedForm) {
                    ForEach(DoseForm.allCases, id: \.self) { form in
                        Text(form.rawValue).tag(form)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 4)
            }

            // Cantidad
            formField(label: "Cantidad") {
                quantitySelector
            }
            .onChange(of: vm.selectedForm) { _, _ in
                if !vm.selectedForm.supportsHalf { vm.addHalf = false }
                if vm.selectedForm == .ampoule && vm.wholeAmount == 0 { vm.wholeAmount = 1 }
            }

            // Hora
            VStack(alignment: .leading, spacing: 12) {
                Text("Hora de la toma")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.gray)
                    .textCase(.uppercase)

                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.scheduledTime.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(tint)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: vm.scheduledTime)

                            Text("hora de la toma")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(Color.gray)
                        }
                        Spacer()
                        Image(systemName: "clock.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(tint.opacity(0.2))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    Divider()
                        .padding(.horizontal, 20)
                        .opacity(0.5)

                    DatePicker("", selection: $vm.scheduledTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .environment(\.locale, Locale(identifier: "es_ES"))
                        .padding(.vertical, 8)
                }
                .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : Color.white.opacity(0.5), lineWidth: 1))
                .shadow(color: Color.black.opacity(isGraphite ? 0.3 : 0.05), radius: 15, y: 5)
            }
            
            // Summary label
            HStack(spacing: 4) {
                Image(systemName: vm.selectedForm.icon)
                    .font(.system(size: 12))
                Text(vm.selectedAmount.displayText(for: vm.selectedForm))
                    .font(.system(.caption, design: .rounded).weight(.medium))
            }
            .foregroundStyle(.secondary)
            .animation(.easeInOut(duration: 0.2), value: vm.selectedAmount)

            // Stock Control
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Control de Stock")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.gray)
                        .textCase(.uppercase)
                    Spacer()
                    if !PremiumManager.shared.isPro {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange))
                    }
                }
                
                VStack(spacing: 0) {
                    Toggle(isOn: Binding(
                        get: { vm.trackStock },
                        set: { newValue in
                            if newValue && !PremiumManager.shared.isPro {
                                showingPaywall = true
                            } else {
                                withAnimation {
                                    vm.trackStock = newValue
                                }
                            }
                        }
                    )) {
                        Text("Llevar control de inventario")
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundStyle(.primary)
                    }
                    .tint(tint)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    
                    if vm.trackStock {
                        Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
                        
                        HStack {
                            Text("Cantidad disponible")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Ej: 30", text: $vm.initialStock)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.primary)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
                        
                        HStack {
                            Text("Avisar cuando queden...")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Ej: 3", text: $vm.lowStockThreshold)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.primary)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : Color.white.opacity(0.5), lineWidth: 1))
                .shadow(color: Color.black.opacity(isGraphite ? 0.3 : 0.05), radius: 15, y: 5)
            }
        }
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
                .background(isGraphite ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isGraphite ? gold.opacity(0.2) : isDark ? Color.green.opacity(0.2) : Color.white.opacity(0.5), lineWidth: 1))
                .shadow(color: Color.black.opacity(isGraphite ? 0.3 : 0.03), radius: 8, y: 2)
        }
    }

    // MARK: - Quantity Selector

    private var wholeOptions: [Int] {
        vm.selectedForm == .ampoule ? [1, 2, 3, 4] : [0, 1, 2, 3, 4]
    }

    private var quantitySelector: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(wholeOptions, id: \.self) { n in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            vm.wholeAmount = n
                            if n == 0 { vm.addHalf = false }
                            if n == 4 { vm.addHalf = false }
                        }
                    } label: {
                        Text("\(n)")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .frame(minWidth: 52, minHeight: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(vm.wholeAmount == n
                                          ? tint
                                          : tint.opacity(0.1))
                                    .shadow(color: vm.wholeAmount == n
                                            ? tint.opacity(0.4)
                                            : Color.clear, radius: 8, y: 4)
                            )
                            .foregroundStyle(vm.wholeAmount == n ? .white : tint)
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: vm.wholeAmount)
                    }
                }
            }
            .padding(.top, 4)

            if vm.selectedForm.supportsHalf {
                Toggle("Añadir media (½)", isOn: $vm.addHalf)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Color.gray)
                    .tint(tint)
            }
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
                    Image(systemName: vm.selectedForm.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(tint)
                        .rotationEffect(.degrees(vm.selectedForm == .pill ? -45 : 0))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(vm.mgText.isEmpty ? vm.selectedAmount.displayText(for: vm.selectedForm) : "\(vm.mgText) mg · \(vm.selectedAmount.displayText(for: vm.selectedForm))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(vm.scheduledTime.formatted(.dateTime.hour().minute()))
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
