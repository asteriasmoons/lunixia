//
//  SymptomLoggerView.swift
//  Lunixia
//

import SwiftUI
import SwiftData

// MARK: - Symptom Logger Page

struct SymptomLoggerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var storeManager: LunixiaStoreManager
    @Query(sort: \LunixiaSymptomLog.date, order: .reverse) private var logs: [LunixiaSymptomLog]

    @State private var showLogSheet      = false
    @State private var showDetailSheet   = false
    @State private var showDeleteConfirm = false
    @State private var selectedLog: LunixiaSymptomLog? = nil
    @State private var editingLog: LunixiaSymptomLog?  = nil
    @State private var showBanner        = false
    @State private var bannerMessage     = ""

    @State private var formSymptoms: [String] = []
    @State private var formSeverity: Int = 0
    @State private var formNote: String = ""
    @State private var formDate: Date = Date()

    private var isPremium: Bool {
        storeManager.isPremium
    }

    private var logsThisWeek: Int {
        logsInSevenDayWindow.count
    }

    private var logsInSevenDayWindow: [LunixiaSymptomLog] {
        let cutoff = LunixiaLimitsManager.startOfSevenDayWindow()
        return logs.filter { $0.date >= cutoff }
    }

    private var canCreateSymptomLog: Bool {
        LunixiaLimitsManager.canCreateSymptomLog(
            currentSevenDayCount: logsInSevenDayWindow.count,
            isPremium: isPremium
        )
    }

    var body: some View {
        ZStack {
            LunixiaBackground().ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Nav
                HStack(spacing: 16) {
                    Text("Symptom Log")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    Spacer()
                    Button { dismiss() } label: {
                        Image("xmarkwavy")
                            .renderingMode(.template)
                            .resizable().scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(LGradients.header)
                    }
                    .buttonStyle(.plain)
                    Button {
                        if canCreateSymptomLog {
                            resetForm()
                            showLogSheet = true
                        } else {
                            showPremiumRequiredMessage()
                        }
                    } label: {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable().scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(canCreateSymptomLog ? LGradients.header : LinearGradient(colors: [LColors.textSecondary.opacity(0.45)], startPoint: .top, endPoint: .bottom))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {

                        // MARK: Overview card
                        GlassCard(padding: 18) {
                            HStack(spacing: 14) {
                                overviewStat(label: "Total Logged", value: logs.count)
                                Rectangle()
                                    .fill(LColors.glassBorder)
                                    .frame(width: 1)
                                    .padding(.vertical, 4)
                                overviewStat(label: "This Week", value: logsThisWeek)
                                    .overlay {
                                        if !canCreateSymptomLog && !isPremium {
                                            LunixiaPremiumBlurOverlay(cornerRadius: 12)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)

                        // MARK: Log cards
                        if logs.isEmpty {
                            GlassCard(padding: 20) {
                                Text("no symptoms logged yet")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary.opacity(0.45))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 16)
                        } else {
                            ForEach(logs) { log in
                                logCard(log)
                                    .padding(.horizontal, 16)
                            }
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .completionBanner(isShowing: showBanner, message: bannerMessage)
        .navigationBarHidden(true)
        .sheet(isPresented: $showLogSheet) {
            SymptomLogSheet(
                editingLog: editingLog,
                symptoms: $formSymptoms,
                severity: $formSeverity,
                note: $formNote,
                date: $formDate
            ) {
                saveLog()
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            if let log = selectedLog {
                SymptomDetailSheet(log: log) {
                    showDetailSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        loadForEdit(log)
                        showLogSheet = true
                    }
                } onDelete: {
                    showDetailSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showDeleteConfirm = true
                    }
                }
            }
        }
        .lunixiaAlertConfirm(
            isPresented: $showDeleteConfirm,
            title: "Delete Entry",
            message: "Are you sure you want to delete this symptom entry?",
            confirmTitle: "Delete",
            confirmRole: .destructive
        ) {
            if let log = selectedLog {
                modelContext.delete(log)
                try? modelContext.save()
                selectedLog = nil
                flash("Entry deleted")
            }
        }
    }

    // MARK: - Overview stat

    @ViewBuilder
    private func overviewStat(label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(LGradients.header)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Log card

    @ViewBuilder
    private func logCard(_ log: LunixiaSymptomLog) -> some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 7) {
                            Image("scope")
                                .renderingMode(.template)
                                .resizable().scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(LGradients.header)
                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                        }

                        if log.severity > 0, let label = LunixiaSymptomLog.severityLabels[log.severity] {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(symptomSeverityColor(log.severity))
                                    .frame(width: 6, height: 6)
                                Text(label)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(symptomSeverityColor(log.severity))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(symptomSeverityColor(log.severity).opacity(0.15))
                                    .overlay(Capsule().strokeBorder(symptomSeverityColor(log.severity).opacity(0.4), lineWidth: 0.75))
                            )
                        }
                    }

                    Spacer()

                    rowIconButton(asset: "dotswavy") {
                        selectedLog = log
                        showDetailSheet = true
                    }
                    rowIconButton(asset: "pencil") {
                        loadForEdit(log)
                        showLogSheet = true
                    }
                    rowIconButton(asset: "trash", tint: LColors.gradientPurple.opacity(0.75)) {
                        selectedLog = log
                        showDeleteConfirm = true
                    }
                }

                if !log.symptoms.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(log.symptoms, id: \.self) { symptom in
                            symptomPill(symptom)
                        }
                    }
                }

                if !log.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(log.note)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private func symptomPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(LColors.textSecondary)
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(LColors.glassSurface, in: Capsule())
            .overlay(Capsule().strokeBorder(LColors.glassBorder, lineWidth: 0.75))
    }

    @ViewBuilder
    private func rowIconButton(asset: String, tint: Color = LColors.textSecondary.opacity(0.7), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(asset)
                .renderingMode(.template).resizable().scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(LColors.glassSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(LColors.glassBorder, lineWidth: 0.75))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func resetForm() {
        editingLog = nil
        formSymptoms = []
        formSeverity = 0
        formNote = ""
        formDate = Date()
    }

    private func loadForEdit(_ log: LunixiaSymptomLog) {
        editingLog = log
        formSymptoms = log.symptoms
        formSeverity = log.severity
        formNote = log.note
        formDate = log.date
    }

    private func saveLog() {
        guard !formSymptoms.isEmpty else { return }

        if editingLog == nil && !canCreateSymptomLog {
            showPremiumRequiredMessage()
            return
        }

        if let existing = editingLog {
            existing.symptoms = formSymptoms
            existing.severity = formSeverity
            existing.note = formNote.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.date = formDate
            existing.updatedAt = Date()
            flash("Entry updated")
        } else {
            let log = LunixiaSymptomLog(
                symptoms: formSymptoms,
                severity: formSeverity,
                note: formNote.trimmingCharacters(in: .whitespacesAndNewlines),
                date: formDate
            )
            modelContext.insert(log)
            flash("Symptoms logged")
        }
        try? modelContext.save()
        resetForm()
    }

    private func showPremiumRequiredMessage() {
        flash("Premium unlocks more symptom logs.")
    }

    private func flash(_ message: String) {
        bannerMessage = message
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { withAnimation { showBanner = false } }
    }
}

// ============================================================
// MARK: - Log / Edit Sheet
// ============================================================

struct SymptomLogSheet: View {
    let editingLog: LunixiaSymptomLog?
    @Binding var symptoms: [String]
    @Binding var severity: Int
    @Binding var note: String
    @Binding var date: Date
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var isEditing: Bool { editingLog != nil }

    var body: some View {
        ZStack {
            LunixiaBackground().ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    HStack {
                        Text(isEditing ? "Edit Entry" : "Log Symptoms")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Spacer()
                        Button { dismiss() } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template).resizable().scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(LGradients.header)
                        }
                        .buttonStyle(.plain)
                    }

                    // ── Date ─────────────────────────────────────────────
                    sheetSection(label: "date") {
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .labelsHidden()
                            .tint(LColors.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }

                    // ── Symptoms ──────────────────────────────────────────
                    sheetSection(label: "symptoms") {
                        VStack(alignment: .leading, spacing: 10) {
                            if !symptoms.isEmpty {
                                HStack(spacing: 6) {
                                    Image("checkwavy")
                                        .renderingMode(.template).resizable().scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(LGradients.header)
                                    Text("\(symptoms.count) selected")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                            }
                            FlowLayout(spacing: 7) {
                                ForEach(LunixiaSymptomLog.allSymptoms, id: \.self) { symptom in
                                    symptomChip(symptom)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }

                    // ── Severity ──────────────────────────────────────────
                    sheetSection(label: "severity") {
                        VStack(spacing: 0) {
                            ForEach(1...5, id: \.self) { level in
                                severityRow(level: level)
                                if level < 5 {
                                    Rectangle().fill(LColors.glassBorder).frame(height: 0.75).padding(.leading, 16)
                                }
                            }
                        }
                    }

                    // ── Note ─────────────────────────────────────────────
                    sheetSection(label: "note (optional)") {
                        TextField("Add a note...", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled()
                            .foregroundStyle(LColors.textPrimary)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }

                    // Save
                    Button {
                        onSave()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image("checkwavy")
                                .renderingMode(.template).resizable().scaledToFit()
                                .frame(width: 14, height: 14)
                            Text(isEditing ? "Save Changes" : "Log Symptoms")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                                .fill(LColors.accentGradient)
                                .shadow(color: LColors.gradientPurple.opacity(0.35), radius: 12, y: 6)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(symptoms.isEmpty)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    @ViewBuilder
    private func sheetSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary.opacity(0.55))
                .kerning(1.2)
            GlassCard(cornerRadius: 14, padding: 0) {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    @ViewBuilder
    private func symptomChip(_ symptom: String) -> some View {
        let selected = symptoms.contains(symptom)
        Button {
            if selected { symptoms.removeAll { $0 == symptom } }
            else        { symptoms.append(symptom) }
        } label: {
            Text(symptom)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? Color.white : LColors.textSecondary)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(
                    selected ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(LGradients.blue.opacity(0.08)),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(selected ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(LColors.glassBorder), lineWidth: selected ? 1.1 : 0.75)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: selected)
    }

    @ViewBuilder
    private func severityRow(level: Int) -> some View {
        let selected = severity == level
        let color = symptomSeverityColor(level)
        let label = LunixiaSymptomLog.severityLabels[level] ?? ""
        Button {
            severity = selected ? 0 : level
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(selected ? Color.white : LColors.glassBorder)
                    .frame(width: 8, height: 8)
                Text("\(level)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(selected ? Color.white : LColors.textSecondary)
                    .frame(width: 16)
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(selected ? Color.white : LColors.textSecondary)
                Spacer()
                if selected {
                    Image("checkwavy")
                        .renderingMode(.template).resizable().scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                selected ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: selected)
    }
}

// ============================================================
// MARK: - Detail Sheet
// ============================================================

struct SymptomDetailSheet: View {
    let log: LunixiaSymptomLog
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LunixiaBackground().ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    HStack {
                        Text("Entry Detail")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Spacer()
                        Button { dismiss() } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template).resizable().scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(LGradients.header)
                        }
                        .buttonStyle(.plain)
                    }

                    GlassCard(padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow(icon: "lovecalendar", label: "Date", value: log.date.formatted(date: .long, time: .shortened))
                            if log.severity > 0, let label = LunixiaSymptomLog.severityLabels[log.severity] {
                                Divider().overlay(LColors.glassBorder)
                                HStack(spacing: 10) {
                                    Image("heartpulse")
                                        .renderingMode(.template).resizable().scaledToFit()
                                        .frame(width: 16, height: 16)
                                        .foregroundStyle(LGradients.header)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("SEVERITY")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundStyle(LColors.textSecondary.opacity(0.55))
                                            .kerning(1)
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(symptomSeverityColor(log.severity))
                                                .frame(width: 7, height: 7)
                                            Text("\(log.severity) — \(label)")
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundStyle(symptomSeverityColor(log.severity))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !log.symptoms.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SYMPTOMS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary.opacity(0.55))
                                .kerning(1.2)
                            FlowLayout(spacing: 7) {
                                ForEach(log.symptoms, id: \.self) { symptom in
                                    Text(symptom)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                        .padding(.horizontal, 11).padding(.vertical, 7)
                                        .background(LColors.glassSurface, in: Capsule())
                                        .overlay(Capsule().strokeBorder(LColors.glassBorder, lineWidth: 0.75))
                                }
                            }
                            .padding(16)
                            .background(LColors.glassSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.glassBorder, lineWidth: 0.75))
                        }
                    }

                    if !log.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary.opacity(0.55))
                                .kerning(1.2)
                            Text(log.note)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(LColors.glassSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.glassBorder, lineWidth: 0.75))
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                            onDelete()
                        } label: {
                            HStack(spacing: 6) {
                                Image("trash")
                                    .renderingMode(.template).resizable().scaledToFit()
                                    .frame(width: 13, height: 13)
                                Text("Delete")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(LColors.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                                    .fill(LColors.danger.opacity(0.12))
                                    .overlay(RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous).strokeBorder(LColors.danger.opacity(0.35), lineWidth: 0.75))
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                            onEdit()
                        } label: {
                            HStack(spacing: 6) {
                                Image("pencilcircle")
                                    .renderingMode(.template).resizable().scaledToFit()
                                    .frame(width: 13, height: 13)
                                Text("Edit Entry")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                                    .fill(LColors.accentGradient)
                                    .shadow(color: LColors.gradientPurple.opacity(0.3), radius: 10, y: 4)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }

    @ViewBuilder
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(icon)
                .renderingMode(.template).resizable().scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LGradients.header)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.55))
                    .kerning(1)
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)
            }
        }
    }
}

// MARK: - Severity color helper (SwiftUI — kept out of the model)

func symptomSeverityColor(_ severity: Int) -> Color {
    switch severity {
    case 1: return Color(red: 0.03, green: 0.86, blue: 0.99)
    case 2: return Color(red: 0.49, green: 0.90, blue: 0.40)
    case 3: return Color(red: 1.0,  green: 0.80, blue: 0.20)
    case 4: return Color(red: 1.0,  green: 0.55, blue: 0.20)
    case 5: return Color(red: 1.0,  green: 0.25, blue: 0.35)
    default: return Color.white.opacity(0.6)
    }
}
