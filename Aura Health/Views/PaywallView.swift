//
//  PaywallView.swift
//  Aura Health
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme {
        colorScheme == .dark ? .blueDark : .light
    }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)
    @State private var showingRestoreAlert = false
    @State private var restoreAlertTitle = ""
    @State private var restoreAlertMessage = ""
    @State private var restoreSucceeded = false
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var selectedPackage: Package? = nil
    
    var body: some View {
        ZStack {
            // Dynamic Glass Background
            (colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color(red: 0.96, green: 0.96, blue: 0.98)).ignoresSafeArea()
            
            // Subtle premium gold glow
            Circle()
                .fill(gold.opacity(colorScheme == .dark ? 0.15 : 0.25))
                .blur(radius: 60)
                .frame(width: 300, height: 300)
                .offset(y: -200)
            
            VStack(spacing: 0) {
                // Top bar with close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(theme.textMuted)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .padding()
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerView
                        
                        // Visual Preview Widget
                        ProGlassPreviewWidget()
                            .padding(.horizontal, 20)
                        
                        featuresView
                        packagesView
                        
                        Spacer().frame(height: 120) // Bottom padding for sticky button
                    }
                }
            }
            
            bottomCTA
        }
        .environment(\.appTheme, theme)
        .onAppear {
            premiumManager.fetchOfferings()
        }
        .onChange(of: premiumManager.availablePackages) { _, packages in
            if selectedPackage == nil {
                selectedPackage = packages.first(where: { $0.packageType == .annual }) ?? packages.first
            }
        }
        .onChange(of: premiumManager.isPro) { _, isPro in
            if isPro {
                dismiss()
            }
        }
        .alert(restoreAlertTitle, isPresented: $showingRestoreAlert) {
            Button("OK", role: .cancel) {
                if restoreSucceeded {
                    dismiss()
                }
            }
        } message: {
            Text(restoreAlertMessage)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .orange.opacity(0.3), radius: 10, y: 5)
            
            Text("Versión PRO")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            
            Text("Desbloquea el máximo potencial.")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
    }
    
    private var featuresView: some View {
        VStack(spacing: 16) {
            FeatureRow(icon: "pills.fill", color: .blue, title: "Medicamentos Ilimitados", subtitle: "Añade todos tus tratamientos sin la restricción de 3 medicinas.")
            FeatureRow(icon: "archivebox.fill", color: .orange, title: "Control de Stock y Farmacia", subtitle: "Avisos automáticos cuando queden pocas pastillas para reponer a tiempo.")
            FeatureRow(icon: "doc.text.fill", color: .teal, title: "Informes Médicos en PDF", subtitle: "Exporta resúmenes clínicos con gráficos de adherencia para tu doctor.")
            FeatureRow(icon: "person.2.fill", color: .indigo, title: "Perfiles Familiares Ilimitados", subtitle: "Supera el límite de 2 perfiles y cuida de padres, hijos o parejas.")
            FeatureRow(icon: "camera.viewfinder", color: .green, title: "Escáner con Cámara", subtitle: "Detecta tus cajas de medicinas y dosis al instante.")
            FeatureRow(icon: "sparkles", color: .purple, title: "Diseño ProGlass y Grafito", subtitle: "Desbloquea la elegante interfaz de cristal líquido y temas oscuros.")
            FeatureRow(icon: "lock.shield.fill", color: .cyan, title: "Face ID y Copia iCloud", subtitle: "Máxima seguridad biométrica y sincronización en la nube.")
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
    }
    
    private var packagesView: some View {
        VStack(spacing: 16) {
            if premiumManager.availablePackages.isEmpty {
                if premiumManager.hasAttemptedFetch {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 30))
                            .foregroundStyle(.orange)
                        
                        Text("No se han podido cargar los planes.")
                            .font(.headline)
                            .foregroundStyle(theme.textPrimary)
                        
                        Text("Es posible que Apple aún esté procesando los datos o propagándolos en los servidores. Vuelve a intentarlo en unos minutos.")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(theme.doseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    ProgressView("Conectando con la App Store...")
                        .padding()
                }
            } else {
                ForEach(premiumManager.availablePackages) { pkg in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPackage = pkg
                        }
                    } label: {
                        PackageRow(
                            identifier: pkg.identifier,
                            title: pkg.storeProduct.localizedTitle,
                            description: pkg.storeProduct.localizedDescription,
                            priceString: pkg.storeProduct.localizedPriceString,
                            hasTrial: pkg.storeProduct.introductoryDiscount != nil,
                            isSelected: selectedPackage?.identifier == pkg.identifier,
                            isPopular: pkg.packageType == .annual
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
    
    private var bottomCTA: some View {
        VStack(spacing: 12) {
            Spacer()
            
            VStack(spacing: 16) {
                if premiumManager.isPurchasing {
                    ProgressView()
                }
                
                Button {
                    if let pkg = selectedPackage {
                        premiumManager.purchase(package: pkg)
                    }
                } label: {
                    Text(selectedPackage != nil ? "Continuar" : "Selecciona un plan")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(selectedPackage != nil ? theme.accent : theme.textMuted)
                        )
                        .shadow(color: selectedPackage != nil ? theme.accent.opacity(0.4) : .clear, radius: 8, y: 4)
                }
                .disabled(selectedPackage == nil || premiumManager.isPurchasing)
                .padding(.horizontal, 24)
                
                // Legal links & Restore
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button {
                            premiumManager.restorePurchases { success in
                                if success {
                                    restoreAlertTitle = "Compras Restauradas"
                                    restoreAlertMessage = "Se han restaurado tus compras exitosamente. Ya tienes acceso a la Versión PRO."
                                    restoreSucceeded = true
                                } else {
                                    restoreAlertTitle = "Sin Compras Previas"
                                    restoreAlertMessage = "No se encontraron suscripciones activas asociadas a este ID de Apple."
                                    restoreSucceeded = false
                                }
                                showingRestoreAlert = true
                            }
                        } label: {
                            Text("Restaurar compras")
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(theme.textPrimary)
                        }
                        
                        Text("•")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(theme.textMuted)
                        
                        Button {
                            premiumManager.presentCodeRedemptionSheet()
                        } label: {
                            Text("Canjear código")
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(theme.textPrimary)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Link("Términos de Uso", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        
                        Text("•")
                            .foregroundStyle(theme.textMuted)
                        
                        // Placeholder URL, user should replace with their actual privacy policy URL
                        Link("Política de Privacidad", destination: URL(string: "https://sites.google.com/view/medicinas-politicaprivacidad/inicio")!)
                    }
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    
                    Text("Puedes cancelar tu suscripción en cualquier momento desde los ajustes de tu cuenta de Apple.")
                        .font(.system(size: 9, weight: .regular, design: .rounded))
                        .foregroundStyle(theme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
            .background(
                theme.backgroundBottom
                    .opacity(0.95)
                    .ignoresSafeArea()
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
            )
        }
    }
}

fileprivate struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

fileprivate struct PackageRow: View {
    let identifier: String
    let title: String
    let description: String
    let priceString: String
    let hasTrial: Bool
    let isSelected: Bool
    let isPopular: Bool
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 16) {
                // Radio button
                Circle()
                    .strokeBorder(isSelected ? theme.accent : theme.textMuted.opacity(0.5), lineWidth: 2)
                    .background(Circle().fill(isSelected ? theme.accent : Color.clear).padding(4))
                    .frame(width: 22, height: 22)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                    
                    if hasTrial {
                        Text("Prueba gratis de 7 días")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(theme.accent)
                    } else {
                        Text(description)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Text(priceString)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.doseCard.opacity(isSelected ? 1 : 0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? theme.accent.opacity(0.8) : theme.accent.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? theme.accent.opacity(0.15) : Color.black.opacity(0.05), radius: 10, y: 4)
            .padding(.top, isPopular ? 10 : 0) // Leave space for the badge
            
            if isPopular {
                Text("MÁS POPULAR")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .offset(y: -4)
            }
        }
    }
}

#Preview {
    PaywallView()
        .environment(\.appTheme, AppTheme.light)
}
