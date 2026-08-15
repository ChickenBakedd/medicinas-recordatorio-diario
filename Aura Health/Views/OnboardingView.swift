import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @Environment(\.appTheme) var theme
    @State private var currentPage = 0
    @State private var showingPaywall = false
    
    var body: some View {
        ZStack {
            theme.backgroundTop.ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    // Pantalla 1: Bienvenida
                    OnboardingPage(
                        image: "pills.fill",
                        title: "Tu salud,\nsiempre al día",
                        description: "Olvídate de recordar horarios. Nosotros nos encargamos de avisarte para que tú solo te preocupes de vivir.",
                        color: theme.accent
                    )
                    .tag(0)
                    
                    // Pantalla 2: Funcionamiento
                    OnboardingPage(
                        image: "bell.badge.fill",
                        title: "Notificaciones Inteligentes",
                        description: "Añade tus medicamentos, configura las horas de toma y recibe recordatorios precisos en tu dispositivo.",
                        color: .blue
                    )
                    .tag(1)
                    
                    // Pantalla 3: PRO y Finalización
                    OnboardingPage(
                        image: "star.fill",
                        title: "Control Total",
                        description: "Gestiona las tomas de toda la familia con la Versión PRO y exporta informes médicos en PDF.",
                        color: .yellow
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(.easeInOut, value: currentPage)
                
                // Botón Continuar / Empezar
                Button(action: {
                    if currentPage < 2 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        
                        if PremiumManager.shared.isPro {
                            withAnimation {
                                hasSeenOnboarding = true
                            }
                            NotificationManager.shared.requestPermissions()
                        } else {
                            showingPaywall = true
                        }
                    }
                }) {
                    Text(currentPage < 2 ? "Siguiente" : "Comenzar")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(theme.accent)
                        )
                        .shadow(color: theme.accent.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showingPaywall, onDismiss: {
            withAnimation {
                hasSeenOnboarding = true
            }
            NotificationManager.shared.requestPermissions()
        }) {
            PaywallView()
        }
    }
}

struct OnboardingPage: View {
    let image: String
    let title: String
    let description: String
    let color: Color
    @Environment(\.appTheme) var theme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(color)
                .padding(40)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(description)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
        .environment(\.appTheme, AppTheme.light)
}
