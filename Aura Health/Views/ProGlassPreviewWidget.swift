//
//  ProGlassPreviewWidget.swift
//  Aura Health
//

import SwiftUI

struct ProGlassPreviewWidget: View {
    @State private var phase = 0.0
    @State private var selectedTheme = 1
    
    let themes = [
        ("Light Glass", "light"),
        ("Dark Glass", "pureBlack"),
        ("Graphite ◆ Gold", "graphite")
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $selectedTheme) {
                ForEach(0..<themes.count, id: \.self) { index in
                    ThemePreviewCard(themeMode: themes[index].1, phase: phase)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 380) // Aumentado para que sea casi media pantalla
            
            // Custom pagination dots
            HStack(spacing: 6) {
                ForEach(0..<themes.count, id: \.self) { index in
                    Circle()
                        .fill(index == selectedTheme ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            
            Text(themes[selectedTheme].0)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.gray)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}

fileprivate struct ThemePreviewCard: View {
    let themeMode: String
    let phase: Double
    
    private var isLight: Bool { themeMode == "light" }
    private var isGraphite: Bool { themeMode == "graphite" }
    
    private var bgColor: Color {
        if isLight { return Color(white: 0.95) }
        if isGraphite { return Color(white: 0.1) }
        return Color(red: 0.05, green: 0.05, blue: 0.1)
    }
    
    private var circle1Color: Color {
        if isLight { return Color.blue.opacity(0.3) }
        if isGraphite { return Color(red: 0.85, green: 0.68, blue: 0.35).opacity(0.3) } // Gold
        return Color.blue.opacity(0.4)
    }
    
    private var circle2Color: Color {
        if isLight { return Color.pink.opacity(0.2) }
        if isGraphite { return Color(red: 0.4, green: 0.1, blue: 0.1).opacity(0.4) } // Dark Red
        return Color.purple.opacity(0.4)
    }
    
    private var textColor: Color {
        if isLight { return .black }
        if isGraphite { return Color(red: 0.9, green: 0.8, blue: 0.6) } // Soft Gold
        return .white
    }
    
    var body: some View {
        ZStack {
            // Animated Holographic Background
            GeometryReader { proxy in
                ZStack {
                    bgColor
                        .ignoresSafeArea()
                    
                    Circle()
                        .fill(circle1Color)
                        .blur(radius: 60)
                        .frame(width: 300, height: 300)
                        .offset(x: cos(phase) * 80, y: sin(phase) * 80)
                    
                    Circle()
                        .fill(circle2Color)
                        .blur(radius: 60)
                        .frame(width: 250, height: 250)
                        .offset(x: -cos(phase) * 60, y: -sin(phase) * 60)
                }
                .drawingGroup() // Optimize rendering
            }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            
            // UI Elements simulating Home Screen
            VStack(alignment: .leading, spacing: 20) {
                // Mock Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hola, María")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(textColor)
                        Text("Tus tomas de hoy")
                            .font(.subheadline)
                            .foregroundStyle(textColor.opacity(0.7))
                    }
                    Spacer()
                    Circle()
                        .fill(textColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(Image(systemName: "person.fill").foregroundStyle(textColor.opacity(0.5)))
                }
                .padding(.horizontal)
                .padding(.top, 24)
                
                // Floating UI Elements simulating DoseCards
                VStack(spacing: 12) {
                    MockGlassCard(title: "Ibuprofeno 600mg", subtitle: "1 cápsula con comida", time: "08:00", textColor: textColor, isLight: isLight)
                    MockGlassCard(title: "Vitamina C", subtitle: "1 comprimido", time: "14:30", textColor: textColor, isLight: isLight)
                    MockGlassCard(title: "Paracetamol", subtitle: "Si hay dolor", time: "20:00", textColor: textColor, isLight: isLight)
                        .opacity(0.5) // Faded to show depth
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [textColor.opacity(0.4), .clear, textColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: isLight ? .black.opacity(0.1) : .black.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal, 5) // Slight padding so shadows don't clip in TabView
    }
}

fileprivate struct MockGlassCard: View {
    let title: String
    let subtitle: String
    let time: String
    let textColor: Color
    let isLight: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(textColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .background(isLight ? .regularMaterial : .ultraThinMaterial, in: Circle())
                
                Image(systemName: "pills.fill")
                    .foregroundStyle(textColor)
                    .font(.title3)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(textColor)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(textColor.opacity(0.7))
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 4) {
                Text(time)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor)
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(red: 0.35, green: 0.72, blue: 0.48))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isLight ? .white.opacity(0.3) : .black.opacity(0.1))
                .background(isLight ? .regularMaterial : .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [textColor.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    ProGlassPreviewWidget()
        .padding()
}
