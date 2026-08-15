//
//  ProGlassAppointmentsListView.swift
//  Aura Health
//

import SwiftUI

struct ProGlassAppointmentsListView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"
    @Bindable var store: MedicationStore
    @State private var editingAppointment: MedicalAppointment? = nil

    private var isGraphite: Bool { appThemeMode == "graphite" }

    var body: some View {
        ZStack {
            glassBackground

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mis Citas")
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(isGraphite ? Color.white.opacity(0.9) : Color.primary.opacity(0.8))
                        Text("\(store.appointments.count) cita\(store.appointments.count == 1 ? "" : "s") agendada\(store.appointments.count == 1 ? "" : "s")")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(isGraphite ? Color.white.opacity(0.35) : Color.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 12)

                if store.appointments.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(store.appointmentsSortedByDate) { appt in
                                ProGlassAppointmentRowCard(appointment: appt) {
                                    editingAppointment = appt
                                } onDelete: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        store.deleteAppointment(id: appt.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .sheet(item: $editingAppointment) { appt in
            ProGlassAddAppointmentView(store: store, existingAppointment: appt)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
    }
    
    private var glassBackground: some View {
        ZStack {
            if isGraphite {
                Color.clear.ignoresSafeArea()
            } else {
                (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 350, height: 350)
                    .blur(radius: 60)
                    .offset(x: -100, y: -200)
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 150, y: 300)
            }
        }
        .ignoresSafeArea()
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.orange.opacity(0.8), Color.pink.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            Text("Sin citas agendadas")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.primary.opacity(0.8))
            Text("Pulsa el botón + para añadir tu primera cita médica")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Row Card

struct ProGlassAppointmentRowCard: View {
    @Environment(\.appTheme) private var theme
    let appointment: MedicalAppointment
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appThemeMode") private var appThemeMode: String = "system"

    private var isDark: Bool { appThemeMode == "pureBlack" }
    private var isGraphite: Bool { appThemeMode == "graphite" }
    private let gold = Color(red: 0.85, green: 0.68, blue: 0.35)

    @State private var showDeleteConfirm = false

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: appointment.date)
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: appointment.date)
    }

    private var isPast: Bool {
        appointment.date < Date()
    }

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                // Date block
                VStack(spacing: 4) {
                    Text(dateLabel.components(separatedBy: " ").first ?? "")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(isPast ? Color.gray : (isDark ? Color.green : isGraphite ? gold : Color.orange))
                    Text(dateLabel.components(separatedBy: " ").last ?? "")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(isPast ? Color.gray.opacity(0.8) : (isDark ? Color.green.opacity(0.8) : isGraphite ? gold.opacity(0.8) : Color.orange.opacity(0.8)))
                        .textCase(.uppercase)
                }
                .frame(width: 50)
                .padding(.vertical, 12)
                .background(
                    isDark ? Color.green.opacity(0.12)
                    : isGraphite ? gold.opacity(0.12)
                    : (colorScheme == .dark ? Color.black : Color.white).opacity(0.6)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(appointment.title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(isPast ? Color.gray : Color.primary.opacity(0.8))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(timeLabel)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                        if let specialty = appointment.specialty {
                            Text("• \(specialty)")
                                .font(.system(.subheadline, design: .rounded))
                        }
                    }
                    .foregroundStyle(isPast ? Color.gray.opacity(0.7) : Color.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isDark ? Color.green.opacity(0.2)
                        : isGraphite ? gold.opacity(0.2)
                        : Color.white.opacity(0.5),
                        lineWidth: 1)
            )
            .opacity(isPast ? 0.6 : 1.0)
            .shadow(color: Color.black.opacity(isPast ? 0 : 0.05), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "¿Eliminar \(appointment.title)?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                onDelete()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borrará esta cita médica. Esta acción no se puede deshacer.")
        }
    }
}
