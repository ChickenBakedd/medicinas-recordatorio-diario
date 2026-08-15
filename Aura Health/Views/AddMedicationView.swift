//
//  AddMedicationView.swift
//  Aura Health
//

import SwiftUI

struct AddMedicationView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: MedicationStore
    @State private var vm: AddMedicationViewModel
    @State private var showingPaywall = false
    
    init(store: MedicationStore, existingDose: MedicationDose? = nil) {
        self.store = store
        _vm = State(initialValue: AddMedicationViewModel(store: store, existingDose: existingDose))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OptimalBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Free Tier Indicator
                        if !vm.isEditing && !PremiumManager.shared.isPro {
                            HStack(spacing: 8) {
                                Image(systemName: "pills.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(theme.accent)
                                Text("Medicamentos gratuitos: \(store.distinctMedicationNames.count)/3")
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundStyle(theme.textSecondary)
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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(theme.barFill)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Input mode selector (only when adding new)
                        if !vm.isEditing {
                            inputModeSelector
                        }

                        // Form fields
                        formSection

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(vm.isEditing ? "Editar Medicamento" : "Añadir Medicamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(theme.accent)
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
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(vm.canSave ? theme.accent : theme.textMuted)
                    .disabled(!vm.canSave)
                }
            }
            .fullScreenCover(isPresented: $vm.showCamera) {
                CameraOCRView { result in
                    vm.handleScanResult(result)
                }
                .environment(\.appTheme, theme)
            }
            .applyThemeMode()
        }
        .onAppear { vm.loadExistingIfNeeded() }
    }

    // MARK: - Input Mode Selector

    private var inputModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(AddMedicationInputMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        if mode == .camera && !PremiumManager.shared.isPro {
                            showingPaywall = true
                        } else {
                            vm.inputMode = mode
                            if mode == .camera { vm.showCamera = true }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode == .manual ? "pencil" : "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(mode == .manual ? "A mano" : "Con cámara")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        vm.inputMode == mode
                        ? theme.accent
                        : Color.clear
                    )
                    .foregroundStyle(vm.inputMode == mode ? .white : theme.textMuted)
                }
            }
        }
        .background(theme.barFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(theme.accent.opacity(0.2), lineWidth: 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: vm.inputMode)
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 16) {
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
                .padding(.top, 2)
            }

            // Cantidad
            formField(label: "Cantidad") {
                quantitySelector
            }
            .onChange(of: vm.selectedForm) { _, _ in
                // Ampollas no soportan media unidad
                if !vm.selectedForm.supportsHalf { vm.addHalf = false }
                // Ampollas empiezan en 1 mínimo
                if vm.selectedForm == .ampoule && vm.wholeAmount == 0 { vm.wholeAmount = 1 }
            }

            // Hora
            VStack(alignment: .leading, spacing: 8) {
                Text("Hora de la toma")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textMuted)
                    .textCase(.uppercase)

                VStack(spacing: 0) {
                    // Big time display
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vm.scheduledTime.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.accent)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: vm.scheduledTime)

                            Text("hora de la toma")
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(theme.textMuted)
                        }
                        Spacer()
                        Image(systemName: "clock.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(theme.accent.opacity(0.2))
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    Divider()
                        .background(theme.trackGray.opacity(0.4))
                        .padding(.horizontal, 14)

                    // Wheel picker
                    DatePicker("", selection: $vm.scheduledTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .environment(\.locale, Locale(identifier: "es_ES"))
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(theme.barFill)
                        .shadow(color: theme.softShadow, radius: 6, y: 2)
                )
            }


            // Stock Control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Control de Stock")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textMuted)
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
                        HStack(spacing: 8) {
                            Text("Llevar control de inventario")
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .foregroundStyle(theme.textPrimary)
                        }
                    }
                    .tint(theme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    
                    if vm.trackStock {
                        Divider().background(theme.trackGray.opacity(0.4)).padding(.horizontal, 14)
                        
                        HStack {
                            Text("Cantidad disponible")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(theme.textSecondary)
                            Spacer()
                            TextField("Ej: 30", text: $vm.initialStock)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(theme.textPrimary)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        
                        Divider().background(theme.trackGray.opacity(0.4)).padding(.horizontal, 14)
                        
                        HStack {
                            Text("Avisar cuando queden...")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(theme.textSecondary)
                            Spacer()
                            TextField("Ej: 3", text: $vm.lowStockThreshold)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(theme.textPrimary)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(theme.barFill)
                        .shadow(color: theme.softShadow, radius: 6, y: 2)
                )
            }

            // Preview card
            if !vm.name.isEmpty {
                previewCard
            }
        }
    }

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

    // MARK: - Quantity Selector

    /// Whole number options depending on form
    private var wholeOptions: [Int] {
        vm.selectedForm == .ampoule ? [1, 2, 3, 4] : [0, 1, 2, 3, 4]
    }

    private func wholeLabel(_ n: Int) -> String {
        n == 0 ? "½" : "\(n)"
    }

    private var quantitySelector: some View {
        VStack(alignment: .leading, spacing: 12) {

            // --- Integer chips ---
            HStack(spacing: 8) {
                ForEach(wholeOptions, id: \.self) { n in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            vm.wholeAmount = n
                            // Si seleccionas 0, ya está la ½ sola, quita el toggle
                            if n == 0 { vm.addHalf = false }
                            // 4 no tiene media
                            if n == 4 { vm.addHalf = false }
                        }
                    } label: {
                        Text(wholeLabel(n))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .frame(minWidth: 52, minHeight: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(vm.wholeAmount == n
                                          ? theme.accent
                                          : theme.accent.opacity(0.08))
                                    .shadow(color: vm.wholeAmount == n
                                            ? theme.accent.opacity(0.3)
                                            : Color.clear, radius: 6, y: 3)
                            )
                            .foregroundStyle(vm.wholeAmount == n ? .white : theme.accent)
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: vm.wholeAmount)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            // --- Half toggle (only when form supports it and whole < 4) ---
            if vm.selectedForm.supportsHalf && vm.wholeAmount < 4 && vm.wholeAmount > 0 {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        vm.addHalf.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(vm.addHalf ? theme.accent : theme.trackGray, lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                            if vm.addHalf {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(theme.accent)
                            }
                        }
                        Text("+ ½ \(vm.selectedForm.unitSingular())")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(vm.addHalf ? theme.accent : theme.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(vm.addHalf ? theme.accent.opacity(0.08) : theme.barFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(vm.addHalf ? theme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // --- Summary label ---
            HStack(spacing: 4) {
                Image(systemName: vm.selectedForm.icon)
                    .font(.system(size: 12))
                Text(vm.selectedAmount.displayText(for: vm.selectedForm))
                    .font(.system(.caption, design: .rounded).weight(.medium))
            }
            .foregroundStyle(theme.textMuted)
            .animation(.easeInOut(duration: 0.2), value: vm.selectedAmount)
        }
    }

    // kept for back-compat (not used in selector anymore)
    private func validAmounts(for form: DoseForm) -> [DoseAmount] { DoseAmount.allCases }
    private func shortLabel(for amount: DoseAmount) -> String { amount.rawValue }



    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vista previa")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textMuted)
                .textCase(.uppercase)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: vm.selectedForm.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(theme.accent)
                        .rotationEffect(.degrees(vm.selectedForm == .pill ? -45 : 0))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                    Text(vm.mgText.isEmpty ? vm.selectedAmount.displayText(for: vm.selectedForm) : "\(vm.mgText) mg · \(vm.selectedAmount.displayText(for: vm.selectedForm))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                Text(vm.scheduledTime.formatted(.dateTime.hour().minute()))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.accent)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.doseCard)
                    .shadow(color: theme.softShadow, radius: 6, y: 2)
            )
        }
    }
}

#Preview {
    AddMedicationView(store: MedicationStore())
}
