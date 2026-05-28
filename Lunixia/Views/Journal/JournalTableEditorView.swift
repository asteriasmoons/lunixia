//
//  JournalTableEditorView.swift
//  Lunixia
//

import SwiftUI
import UIKit

// MARK: - Table Editor

struct JournalTableEditorView: View {
    @Bindable var block: JournalBlock
    var journalTextColor: UIColor = UIColor(LColors.textPrimary)

    @State private var tableData: JournalTableData = JournalTableData()
    @State private var focusedCell: CellID? = nil
    @State private var focusedCellRange: NSRange = NSRange(location: 0, length: 0)
    @State private var showLinkEditor = false
    @State private var linkDraft = ""
    @State private var showHighlightPicker = false
    @State private var highlightColor1: Color = .white
    @State private var highlightColor2: Color = Color(red: 0.78, green: 0.49, blue: 1)
    @State private var showCellColorPicker = false
    @State private var cellColorSelection: Color = Color(red: 0.30, green: 0.59, blue: 1).opacity(0.3)
    @State private var selectedCells: Set<CellID> = []
    @State private var isSelectingCells: Bool = false

    struct CellID: Hashable { let row: Int; let col: Int }

    private var hasSelection: Bool { focusedCellRange.length > 0 }
    private var effectiveRange: NSRange {
        if focusedCellRange.length > 0 { return focusedCellRange }
        if let cell = focusedCell {
            let len = (tableData.cell(row: cell.row, col: cell.col) as NSString).length
            return NSRange(location: 0, length: len)
        }
        return NSRange(location: 0, length: 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Format + highlight — only when text is selected
            if focusedCellRange.length > 0, let cell = focusedCell {
                HStack(spacing: 8) {
                    Menu {
                        Button(cellHasStyle(.bold, cell: cell) ? "Remove Bold" : "Bold") { toggleCellStyle(.bold, cell: cell) }
                        Button(cellHasStyle(.italic, cell: cell) ? "Remove Italic" : "Italic") { toggleCellStyle(.italic, cell: cell) }
                        Button(cellHasStyle(.underline, cell: cell) ? "Remove Underline" : "Underline") { toggleCellStyle(.underline, cell: cell) }
                        Button(cellHasStyle(.strikethrough, cell: cell) ? "Remove Strikethrough" : "Strikethrough") { toggleCellStyle(.strikethrough, cell: cell) }
                        Button(cellHasStyle(.inlineCode, cell: cell) ? "Remove Code" : "Code") { toggleCellStyle(.inlineCode, cell: cell) }
                        Button(cellHasStyle(.link, cell: cell) ? "Edit Link" : "Add Link") { prepareLinkEditor(cell: cell) }
                    } label: {
                        Text("Format")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LGradients.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(LGradients.blue, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let existing = tableData.cellStyles(row: cell.row, col: cell.col).first(where: {
                            $0.type == .highlight && NSEqualRanges($0.nsRange, effectiveRange)
                        }) {
                            let parts = existing.urlString.components(separatedBy: ":")
                            if parts.count == 2 {
                                highlightColor1 = Color(uiColorFromHex(parts[0]) ?? .white)
                                highlightColor2 = Color(uiColorFromHex(parts[1]) ?? .purple)
                            }
                        }
                        showHighlightPicker = true
                    } label: {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LColors.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(LColors.glassBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showHighlightPicker) {
                        highlightSheet(cell: cell)
                            .presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                            .preferredColorScheme(.dark)
                    }
                }
            }

            // Cell color — always visible while editing the table
            if let cell = focusedCell {
                Button {
                    let hex = isSelectingCells && !selectedCells.isEmpty
                        ? tableData.cellBgColor(row: selectedCells.first!.row, col: selectedCells.first!.col)
                        : tableData.cellBgColor(row: cell.row, col: cell.col)
                    cellColorSelection = hex.isEmpty
                        ? Color(red: 0.30, green: 0.59, blue: 1).opacity(0.25)
                        : Color(uiColorFromHex(hex) ?? UIColor(red: 0.30, green: 0.59, blue: 1, alpha: 0.25))
                    showCellColorPicker = true
                } label: {
                    let hex = tableData.cellBgColor(row: cell.row, col: cell.col)
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(hex.isEmpty ? Color.white.opacity(0.15) : Color(uiColorFromHex(hex) ?? .clear))
                                .frame(width: 22, height: 22)
                                .overlay(Circle().stroke(LColors.glassBorder, lineWidth: 1))
                            Image("paintdrop")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(.white)
                        }
                        Text(isSelectingCells && !selectedCells.isEmpty
                             ? "Color \(selectedCells.count) Cell\(selectedCells.count == 1 ? "" : "s")"
                             : (hex.isEmpty ? "Cell Color" : "Change Color"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white)

                        if isSelectingCells {
                            Spacer()
                            Button("Done") {
                                isSelectingCells = false
                                selectedCells.removeAll()
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LGradients.blue)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(LColors.glassBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showCellColorPicker) {
                    cellColorSheet(cell: cell)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                        .preferredColorScheme(.dark)
                }
            }

            // Table grid
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(0..<tableData.rowCount, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<tableData.colCount, id: \.self) { col in
                                let cellID = CellID(row: row, col: col)
                                let isSelected = selectedCells.contains(cellID)

                                JournalRichTableCellView(
                                    tableData: tableData,
                                    row: row, col: col,
                                    isHeader: row == 0,
                                    textColor: journalTextColor,
                                    bgColorHex: tableData.cellBgColor(row: row, col: col),
                                    onTextChange: { newText in
                                        tableData.setCell(row: row, col: col, value: newText)
                                        saveTable()
                                    },
                                    onFocus: {
                                        if !isSelectingCells {
                                            focusedCell = cellID
                                        }
                                    },
                                    onRangeChange: { range in
                                        if !isSelectingCells {
                                            focusedCell = cellID
                                            focusedCellRange = range
                                        }
                                    }
                                )
                                .allowsHitTesting(!isSelectingCells)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(isSelected
                                              ? AnyShapeStyle(LGradients.blue.opacity(0.22))
                                              : AnyShapeStyle(Color.clear))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(isSelected
                                                ? AnyShapeStyle(LGradients.blue)
                                                : AnyShapeStyle(Color.clear), lineWidth: 1.5)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard isSelectingCells else { return }
                                    if selectedCells.contains(cellID) {
                                        selectedCells.remove(cellID)
                                    } else {
                                        selectedCells.insert(cellID)
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        isSelectingCells = true
                                        selectedCells = [cellID]
                                        focusedCell = cellID
                                    } label: {
                                        Label("Select Multiple", systemImage: "checkmark.circle")
                                    }
                                }

                                if col < tableData.colCount - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(width: 1)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)

                        if row < tableData.rowCount - 1 {
                            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
                        }
                    }
                }
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }

            // Controls
            HStack(spacing: 8) {
                controlButton(icon: "plus", label: "Row") {
                    tableData.addRow(); saveTable()
                }
                controlButton(icon: "plus", label: "Col") {
                    tableData.addColumn(); saveTable()
                }
                if tableData.rowCount > 1 {
                    controlButton(icon: "minus", label: "Row") {
                        tableData.deleteRow(at: tableData.rowCount - 1); saveTable()
                    }
                }
                if tableData.colCount > 1 {
                    controlButton(icon: "minus", label: "Col") {
                        tableData.deleteColumn(at: tableData.colCount - 1); saveTable()
                    }
                }
            }
        }
        .onAppear {
            tableData = JournalTableData.from(block.text)
        }
        .alert("Insert Link", isPresented: $showLinkEditor) {
            TextField("https://example.com", text: $linkDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) { linkDraft = "" }
            Button("Apply") {
                if let cell = focusedCell { applyLink(cell: cell) }
            }
        }
    }

    // MARK: - Controls

    private func controlButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LColors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(LColors.glassBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cell color sheet

    private func cellColorSheet(cell: CellID) -> some View {
        NavigationStack {
            ZStack {
                LunixiaBackground().ignoresSafeArea()
                VStack(spacing: 24) {
                    ColorPicker("Cell Color", selection: $cellColorSelection, supportsOpacity: true)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LColors.textPrimary)
                        .padding(.horizontal, LSpacing.pageHorizontal)

                    if !tableData.cellBgColor(row: cell.row, col: cell.col).isEmpty
                        || (isSelectingCells && selectedCells.contains { !tableData.cellBgColor(row: $0.row, col: $0.col).isEmpty }) {
                        Button {
                            let targets: [CellID] = isSelectingCells && !selectedCells.isEmpty
                                ? Array(selectedCells)
                                : [cell]
                            for target in targets {
                                tableData.setCellBgColor(row: target.row, col: target.col, hex: "")
                            }
                            saveTable()
                            showCellColorPicker = false
                        } label: {
                            Text(isSelectingCells && selectedCells.count > 1
                                 ? "Remove Color from All"
                                 : "Remove Color")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(LColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Cell Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        let uiColor = UIColor(cellColorSelection)
                        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                        let hex = String(format: "%02X%02X%02X%02X",
                            Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
                        let targets: [CellID] = isSelectingCells && !selectedCells.isEmpty
                            ? Array(selectedCells)
                            : [cell]
                        for target in targets {
                            tableData.setCellBgColor(row: target.row, col: target.col, hex: hex)
                        }
                        saveTable()
                        showCellColorPicker = false
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Highlight sheet

    private func highlightSheet(cell: CellID) -> some View {
        NavigationStack {
            ZStack {
                LunixiaBackground().ignoresSafeArea()
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 16) {
                        ColorPicker("Color 1", selection: $highlightColor1, supportsOpacity: false)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LColors.textPrimary)
                        ColorPicker("Color 2", selection: $highlightColor2, supportsOpacity: false)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LColors.textPrimary)
                    }
                    .padding(.horizontal, LSpacing.pageHorizontal)

                    Canvas { ctx, size in
                        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                            Gradient(colors: [highlightColor1, highlightColor2]),
                            startPoint: CGPoint(x: 0, y: size.height / 2),
                            endPoint: CGPoint(x: size.width, y: size.height / 2)
                        ))
                    }
                    .frame(width: 160, height: 28)
                    .mask {
                        Text("Highlight Text")
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 160, height: 28)
                    }

                    Button {
                        applyHighlight(cell: cell)
                        showHighlightPicker = false
                    } label: {
                        Text("Apply Highlight")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LGradients.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, LSpacing.pageHorizontal)

                    if cellHasStyle(.highlight, cell: cell) {
                        Button {
                            removeCellStyle(.highlight, cell: cell)
                            showHighlightPicker = false
                        } label: {
                            Text("Remove Highlight")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(LColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.top, 28)
            }
            .navigationTitle("Highlight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Style helpers

    private func cellHasStyle(_ type: JournalInlineStyleType, cell: CellID) -> Bool {
        let range = effectiveRange
        guard range.length > 0 else { return false }
        return tableData.cellStyles(row: cell.row, col: cell.col).contains {
            $0.type == type && NSEqualRanges($0.nsRange, range)
        }
    }

    private func toggleCellStyle(_ type: JournalInlineStyleType, cell: CellID) {
        let range = effectiveRange
        guard range.length > 0 else { return }
        var existing = tableData.cellStyles(row: cell.row, col: cell.col)
        if let idx = existing.firstIndex(where: { $0.type == type && NSEqualRanges($0.nsRange, range) }) {
            existing.remove(at: idx)
        } else {
            existing.append(JournalTableCellStyle(
                typeRaw: type.rawValue,
                rangeLocation: range.location,
                rangeLength: range.length,
                urlString: ""
            ))
        }
        tableData.setCellStyles(row: cell.row, col: cell.col, styles: existing)
        saveTable()
    }

    private func removeCellStyle(_ type: JournalInlineStyleType, cell: CellID) {
        let range = effectiveRange
        var existing = tableData.cellStyles(row: cell.row, col: cell.col)
        existing.removeAll { $0.type == type && NSEqualRanges($0.nsRange, range) }
        tableData.setCellStyles(row: cell.row, col: cell.col, styles: existing)
        saveTable()
    }

    private func prepareLinkEditor(cell: CellID) {
        let range = effectiveRange
        if let existing = tableData.cellStyles(row: cell.row, col: cell.col).first(where: {
            $0.type == .link && NSEqualRanges($0.nsRange, range)
        }) {
            linkDraft = existing.urlString
        } else {
            linkDraft = ""
        }
        showLinkEditor = true
    }

    private func applyLink(cell: CellID) {
        let range = effectiveRange
        let trimmed = linkDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        var existing = tableData.cellStyles(row: cell.row, col: cell.col)
        existing.removeAll { $0.type == .link && NSEqualRanges($0.nsRange, range) }
        if !trimmed.isEmpty {
            existing.append(JournalTableCellStyle(
                typeRaw: JournalInlineStyleType.link.rawValue,
                rangeLocation: range.location,
                rangeLength: range.length,
                urlString: trimmed
            ))
        }
        tableData.setCellStyles(row: cell.row, col: cell.col, styles: existing)
        saveTable()
        linkDraft = ""
    }

    private func applyHighlight(cell: CellID) {
        let range = effectiveRange
        guard range.length > 0 else { return }
        let fg = hexStringFromColor(UIColor(highlightColor1))
        let bg = hexStringFromColor(UIColor(highlightColor2))
        var existing = tableData.cellStyles(row: cell.row, col: cell.col)
        existing.removeAll { $0.type == .highlight && NSEqualRanges($0.nsRange, range) }
        existing.append(JournalTableCellStyle(
            typeRaw: JournalInlineStyleType.highlight.rawValue,
            rangeLocation: range.location,
            rangeLength: range.length,
            urlString: "\(fg):\(bg)"
        ))
        tableData.setCellStyles(row: cell.row, col: cell.col, styles: existing)
        saveTable()
    }

    private func hexStringFromColor(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private func saveTable() {
        block.text = tableData.toJSON()
        block.touch()
    }
}

private func uiColorFromHex(_ hex: String) -> UIColor? {
    var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)

    if cleaned.hasPrefix("#") {
        cleaned.removeFirst()
    }

    if cleaned.count == 3 {
        cleaned = cleaned.map { "\($0)\($0)" }.joined()
    }

    guard cleaned.count == 6 || cleaned.count == 8,
          let value = UInt64(cleaned, radix: 16) else {
        return nil
    }

    if cleaned.count == 8 {
        let red = CGFloat((value & 0xFF000000) >> 24) / 255
        let green = CGFloat((value & 0x00FF0000) >> 16) / 255
        let blue = CGFloat((value & 0x0000FF00) >> 8) / 255
        let alpha = CGFloat(value & 0x000000FF) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    let red = CGFloat((value & 0xFF0000) >> 16) / 255
    let green = CGFloat((value & 0x00FF00) >> 8) / 255
    let blue = CGFloat(value & 0x0000FF) / 255

    return UIColor(red: red, green: green, blue: blue, alpha: 1)
}

// MARK: - Rich cell UIViewRepresentable

final class JournalTableCellTextView: UITextView {
    var onPaste: ((String) -> Void)?

    override func paste(_ sender: Any?) {
        super.paste(sender)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onPaste?(self.text ?? "")
            self.invalidateIntrinsicContentSize()
        }
    }
}

struct JournalRichTableCellView: UIViewRepresentable {
    let tableData: JournalTableData
    let row: Int
    let col: Int
    let isHeader: Bool
    let textColor: UIColor
    let bgColorHex: String
    let onTextChange: (String) -> Void
    let onFocus: () -> Void
    let onRangeChange: (NSRange) -> Void

    private var bgUIColor: UIColor? {
        bgColorHex.isEmpty ? nil : uiColorFromHex(bgColorHex)
    }

    private var baseFont: UIFont {
        isHeader
            ? .systemFont(ofSize: 13, weight: .bold)
            : .systemFont(ofSize: 13, weight: .regular)
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> JournalTableCellTextView {
        let tv = JournalTableCellTextView()
        tv.isScrollEnabled = false
        tv.delegate = context.coordinator
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainer.widthTracksTextView = true
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let coordinator = context.coordinator
        tv.onPaste = { newText in
            coordinator.parent.onTextChange(newText)
        }
        return tv
    }

    func updateUIView(_ uiView: JournalTableCellTextView, context: Context) {
        context.coordinator.parent = self

        uiView.onPaste = { newText in
            context.coordinator.parent.onTextChange(newText)
        }

        if let bg = bgUIColor {
            uiView.backgroundColor = bg
        } else if isHeader {
            uiView.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        } else {
            uiView.backgroundColor = .clear
        }

        let attributed = tableData.attributedText(row: row, col: col, baseFont: baseFont, textColor: textColor)

        if uiView.isFirstResponder {
            guard uiView.text == attributed.string else { return }
            let prior = uiView.selectedRange
            context.coordinator.isUpdating = true
            uiView.attributedText = attributed
            let safeLocation = min(prior.location, attributed.length)
            let safeLength = min(prior.length, attributed.length - safeLocation)
            uiView.selectedRange = NSRange(location: safeLocation, length: max(0, safeLength))
            context.coordinator.isUpdating = false
        } else {
            if uiView.attributedText != attributed {
                context.coordinator.isUpdating = true
                uiView.attributedText = attributed
                context.coordinator.isUpdating = false
                uiView.invalidateIntrinsicContentSize()
            }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: JournalTableCellTextView, context: Context) -> CGSize? {
        let w = min(proposal.width ?? 120, 200)
        let fitting = uiView.sizeThatFits(CGSize(width: w, height: .greatestFiniteMagnitude))
        return CGSize(width: max(80, w), height: max(baseFont.lineHeight + 16, fitting.height))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: JournalRichTableCellView
        var isUpdating = false

        init(parent: JournalRichTableCellView) { self.parent = parent }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onFocus()
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            parent.onTextChange(textView.text ?? "")
            textView.invalidateIntrinsicContentSize()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isUpdating else { return }
            parent.onRangeChange(textView.selectedRange)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            let attributed = parent.tableData.attributedText(
                row: parent.row, col: parent.col,
                baseFont: parent.isHeader
                    ? .systemFont(ofSize: 13, weight: .bold)
                    : .systemFont(ofSize: 13, weight: .regular),
                textColor: parent.textColor
            )
            isUpdating = true
            textView.attributedText = attributed
            isUpdating = false
            textView.invalidateIntrinsicContentSize()
        }
    }
}
