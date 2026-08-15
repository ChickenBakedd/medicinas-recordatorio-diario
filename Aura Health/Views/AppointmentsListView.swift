//
//  AppointmentsListView.swift
//  Aura Health
//

import SwiftUI

struct AppointmentsListView: View {
    @Environment(\.appTheme) private var theme
    @Bindable var store: MedicationStore
    @State private var editingAppointment: MedicalAppointment? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mis Citas")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.textPrimary)
                        Text("\(store.appointments.count) cita\(store.appointments.count == 1 ? "" : "s") agendada\(store.appointments.count == 1 ? "" : "s")")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(theme.textMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 12)

                if store.appointments.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.appointmentsSortedByDate) { appt in
                            AppointmentRowCard(appointment: appt) {
                                editingAppointment = appt
                            } onDelete: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    store.deleteAppointment(id: appt.id)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .sheet(item: $editingAppointment) { appt in
            AddAppointmentView(store: store, existingAppointment: appt)
                .environment(\.appTheme, theme)
                .applyThemeMode()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [appointmentTint.opacity(0.15), appointmentTint.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40))
                    .foregroundStyle(appointmentTint)
            }
            Text("Sin citas agendadas")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(theme.textPrimary)
            Text("Pulsa el botón + para añadir tu primera cita médica")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private let appointmentTint = Color(red: 0.75, green: 0.45, blue: 0.32)
}

// MARK: - Row Card

struct AppointmentRowCard: View {
    @Environment(\.appTheme) private var theme
    let appointment: MedicalAppointment
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let tint = Color(red: 0.75, green: 0.45, blue: 0.32)

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
                VStack(spacing: 2) {
                    Text(dateLabel.components(separatedBy: " ").first ?? "")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(isPast ? theme.textMuted : tint)
                    Text(dateLabel.components(separatedBy: " ").last ?? "")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(isPast ? theme.textMuted : tint)
                        .textCase(.uppercase)
                }
                .frame(width: 44)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isPast ? theme.textMuted.opacity(0.08) : tint.opacity(0.1))
                )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(isPast ? theme.textMuted : theme.textPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(timeLabel)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                        if let specialty = appointment.specialty {
                            Text("· \(specialty)")
                                .font(.system(.subheadline, design: .rounded))
                        }
                        
                        // Indicators for notes and attachments
                        if appointment.notes != nil || !(appointment.attachments?.isEmpty ?? true) {
                            Text("·")
                                .font(.system(.caption, design: .rounded))
                            HStack(spacing: 4) {
                                if appointment.notes != nil {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 10))
                                }
                                if let attachments = appointment.attachments, !attachments.isEmpty {
                                    Image(systemName: "paperclip")
                                        .font(.system(size: 10))
                                    Text("\(attachments.count)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                }
                            }
                            .foregroundStyle(tint.opacity(0.8))
                        }
                    }
                    .foregroundStyle(isPast ? theme.textMuted : theme.textSecondary)
                }

                Spacer()

                if isPast {
                    Text("Pasada")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(theme.textMuted.opacity(0.1)))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(theme.textMuted)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.appointmentsCard.opacity(isPast ? 0.6 : 1.0))
                    .shadow(color: theme.softShadow, radius: 8, y: 3)
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Eliminar", systemImage: "trash.fill")
            }
        }
    }
}

#Preview {
    AppointmentsListView(store: MedicationStore())
}
