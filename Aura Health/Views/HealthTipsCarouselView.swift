import SwiftUI
import Combine

struct HealthTipsCarouselView: View {
    @Environment(\.appTheme) private var theme
    @AppStorage("appUIStyle") private var appUIStyle: String = "classic"
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    
    private var isGraphite: Bool { appUIStyle == "proGlass" && appThemeMode == "graphite" }
    private var isDark: Bool { appUIStyle == "proGlass" && appThemeMode == "pureBlack" }
    
    @State private var currentTips: [HealthTip] = Array(HealthTip.allTips.shuffled().prefix(3))
    @State private var currentIndex: Int = 0
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 6.0, on: .main, in: .common)
    @State private var timerCancellable: Cancellable?
    
    var body: some View {
        Group {
            if !currentTips.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(0..<currentTips.count, id: \.self) { index in
                        tipCard(for: currentTips[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 135)
                .onReceive(timer) { _ in
                    withAnimation {
                        currentIndex = (currentIndex + 1) % currentTips.count
                    }
                }
                .onAppear {
                    startTimer()
                }
                .onDisappear {
                    stopTimer()
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { _ in
                            // Pause the timer when the user manually interacts
                            stopTimer()
                        }
                        .onEnded { _ in
                            // Restart after a small delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                startTimer()
                            }
                        }
                )
            } else {
                EmptyView()
            }
        }
    }
    
    private func tipCard(for tip: HealthTip) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tip.color.opacity(appUIStyle == "proGlass" ? 0.2 : 0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: tip.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(tip.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(tip.title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(appUIStyle == "proGlass" ? (isGraphite ? .white.opacity(0.9) : .primary.opacity(0.9)) : theme.textPrimary)
                    
                    Spacer()
                }
                
                Text(tip.description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(appUIStyle == "proGlass" ? (isGraphite ? .white.opacity(0.6) : .secondary) : theme.textSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(16)
        .background(
            Group {
                if appUIStyle == "proGlass" {
                    if isGraphite {
                        Color.white.opacity(0.05)
                    } else {
                        Color.clear.background(.ultraThinMaterial)
                    }
                } else {
                    theme.chipFill
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            Group {
                if appUIStyle == "proGlass" {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tip.color.opacity(isGraphite ? 0.3 : 0.2), lineWidth: 1)
                } else {
                    EmptyView()
                }
            }
        )
        .shadow(color: appUIStyle == "proGlass" ? .clear : theme.softShadow, radius: 4, y: 2)
        .padding(.horizontal, appUIStyle == "proGlass" ? 24 : 0)
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: 6.0, on: .main, in: .common)
        timerCancellable = timer.connect()
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
    }
}
