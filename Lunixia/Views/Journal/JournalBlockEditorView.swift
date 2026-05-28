//
//  JournalBlockEditorView.swift
//  Lunixia
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Notification Names

extension Notification.Name {
    static let journalBlockRequestFocus = Notification.Name("JournalBlockRequestFocus")
    static let journalBlockDidFocus = Notification.Name("JournalBlockDidFocus")
    static let journalBlockRequestMentionPicker = Notification.Name("JournalBlockRequestMentionPicker")
    static let journalBlockRequestFocusNextParagraph = Notification.Name("JournalBlockRequestFocusNextParagraph")
}

struct JournalBlockEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var entry: JournalEntry
    @Binding var focusedBlockID: UUID?
    /// Optional identity header injected at the top of the first page card
    var identityHeader: AnyView? = nil
    @State private var isMutatingBlocks = false

    private var innerPageMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }
    @State private var draggingBlock: JournalBlock? = nil
    @State private var dragOverIndex: Int? = nil
    @State private var selectedBlockIDs: Set<UUID> = []
    @State private var isKeyboardVisible: Bool = false
    @State private var scrollToFocusedBlockWorkItem: DispatchWorkItem? = nil

    // Split visible blocks into page segments at .pageBreak dividers.
    // Each entry: (indexed page blocks, optional page break block that follows it)
    private var blockPages: [(blocks: [(Int, JournalBlock)], breakBlock: JournalBlock?)] {
        var pages: [(blocks: [(Int, JournalBlock)], breakBlock: JournalBlock?)] = [([], nil)]
        for item in Array(visibleBlocks.enumerated()) {
            let block = item.element
            if block.type == .divider,
               (DividerStyle(rawValue: block.languageHint) ?? .line) == .pageBreak {
                let last = pages[pages.count - 1]
                pages[pages.count - 1] = (last.blocks, block)
                pages.append(([], nil))
            } else {
                pages[pages.count - 1].blocks.append((item.offset, block))
            }
        }
        return pages
    }

    private var resolvedJournalTextColor: UIColor {
        let hex = entry.textColorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !hex.isEmpty,
              let r = UInt8(hex.prefix(2), radix: 16),
              let g = UInt8(hex.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(hex.dropFirst(4).prefix(2), radix: 16) else {
            return UIColor(LColors.textPrimary)
        }
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let pages = blockPages

                    // Drop zone before everything
                    if draggingBlock != nil {
                        BlockDropZone(index: 0, dragOverIndex: $dragOverIndex)
                            .onDrop(of: [.plainText], delegate: IndexedDropDelegate(
                                index: 0,
                                draggingBlock: $draggingBlock,
                                dragOverIndex: $dragOverIndex,
                                visibleBlocks: visibleBlocks,
                                onMove: reorderBlockToIndex
                            ))
                    }

                    ForEach(Array(pages.enumerated()), id: \.offset) { pageIndex, pageEntry in
                        journalPageCard(pageIndex: pageIndex, pageEntry: pageEntry)
                    }
                }
                .padding(.bottom, isKeyboardVisible ? 260 : 140)
                .frame(maxWidth: innerPageMaxWidth, alignment: .top)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .defaultScrollAnchor(.top)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomAddBlockBar
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
                scrollFocusedBlockIntoView(proxy: proxy, delay: 0.18)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .journalBlockDidFocus)) { note in
                if let id = note.object as? UUID {
                    focusedBlockID = id
                    scrollFocusedBlockIntoView(proxy: proxy)
                }
            }
            .onChange(of: focusedBlockID) { _, _ in
                scrollFocusedBlockIntoView(proxy: proxy)
            }
            .onChange(of: entry.updatedAt) { _, _ in
                guard isKeyboardVisible else { return }
                scrollFocusedBlockIntoView(proxy: proxy, delay: 0.05)
            }
            .onDisappear {
                scrollToFocusedBlockWorkItem?.cancel()
                scrollToFocusedBlockWorkItem = nil
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func journalPageCard(
        pageIndex: Int,
        pageEntry: (blocks: [(Int, JournalBlock)], breakBlock: JournalBlock?)
    ) -> some View {
        let page = pageEntry.blocks

        journalPageCardContent(pageIndex: pageIndex, page: page)
            .background(journalPageCardBackground(pageIndex: pageIndex, page: page))
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

        if let breakBlock = pageEntry.breakBlock {
            journalBlockRow(for: breakBlock)
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func journalPageCardContent(pageIndex: Int, page: [(Int, JournalBlock)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if pageIndex == 0, let header = identityHeader {
                header
            }

            VStack(alignment: .leading, spacing: 0) {
                if page.isEmpty {
                    Text("Tap to write...")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(LColors.textSecondary.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    journalPageRows(page: page)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .padding(.top, (pageIndex == 0 && identityHeader != nil) ? 8 : 28)
        }
    }

    @ViewBuilder
    private func journalPageRows(page: [(Int, JournalBlock)]) -> some View {
        ForEach(page, id: \.1.id) { (i, block) in
            journalBlockRow(for: block)
                .opacity(draggingBlock?.id == block.id ? 0.4 : 1)
                .onDrag {
                    draggingBlock = block
                    dragOverIndex = nil
                    return NSItemProvider(object: block.id.uuidString as NSString)
                }
                .padding(.vertical, isSelectionMode ? 3 : 6)

            if draggingBlock != nil {
                BlockDropZone(index: i + 1, dragOverIndex: $dragOverIndex)
                    .onDrop(of: [.plainText], delegate: IndexedDropDelegate(
                        index: i + 1,
                        draggingBlock: $draggingBlock,
                        dragOverIndex: $dragOverIndex,
                        visibleBlocks: visibleBlocks,
                        onMove: reorderBlockToIndex
                    ))
            }
        }
    }

    private func journalPageCardBackground(pageIndex: Int, page: [(Int, JournalBlock)]) -> some View {
        let style = JournalInnerPageStyle(entry: entry)

        return RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.clear)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(style.shouldShowMaterial ? 1 : 0)
            )
            .overlay {
                style.fillView
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(style.borderColor, lineWidth: 1)
            )
            .overlay(
                PageSheetTapOverlay { _ in
                    handlePageCardTap(pageIndex: pageIndex, page: page)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            )
    }

    private func handlePageCardTap(pageIndex: Int, page: [(Int, JournalBlock)]) {
        guard !isSelectionMode else { return }

        if page.isEmpty {
            let allPages = blockPages
            if pageIndex > 0, let breakBlock = allPages[pageIndex - 1].breakBlock {
                insertBlockBelow(breakBlock, .paragraph, "")
            }
        } else if let last = page.last?.1 {
            if last.type == .paragraph && last.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let id = last.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    NotificationCenter.default.post(name: .journalBlockRequestFocus, object: id)
                }
            } else {
                insertBlockBelow(last, .paragraph, "")
            }
        }
    }

    @ViewBuilder
    private func journalBlockRow(for block: JournalBlock) -> some View {
        JournalBlockRow(
            block: block,
            onAddBelow: { b, type, initialText in insertBlockBelow(b, type, initialText) },
            onDelete: deleteBlock,
            onMoveUp: moveBlockUp,
            onMoveDown: moveBlockDown,
            onTransform: transformBlock,
            isSelectionMode: isSelectionMode,
            isSelectedForBatchAction: selectedBlockIDs.contains(block.id),
            selectedBlockCount: selectedBlockIDs.count,
            onEnterSelectionMode: enterSelectionMode,
            onToggleBatchSelection: toggleBlockSelection,
            onClearBatchSelection: clearBlockSelection,
            onDeleteSelectedBlocks: deleteSelectedBlocks,
            onIndentSelectedBlocksIn: indentSelectedBlocksIn,
            onIndentSelectedBlocksOut: indentSelectedBlocksOut,
            journalTextColor: resolvedJournalTextColor
        )
        .id(block.id)
    }


    private func scrollFocusedBlockIntoView(proxy: ScrollViewProxy, delay: TimeInterval = 0.08) {
        guard let focusedBlockID else { return }

        scrollToFocusedBlockWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.18)) {
                proxy.scrollTo(focusedBlockID, anchor: .center)
            }
        }

        scrollToFocusedBlockWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    // MARK: - Visible Blocks

    private var visibleBlocks: [JournalBlock] {
        var hiddenParentIDs = Set<UUID>()
        var result: [JournalBlock] = []
        for block in entry.sortedBlocks {
            if let parentID = block.parentBlockID, hiddenParentIDs.contains(parentID) {
                if block.isToggleBlock || block.type.isToggleHeading { hiddenParentIDs.insert(block.id) }
                continue
            }
            result.append(block)
            if (block.isToggleBlock || block.type.isToggleHeading) && !block.isExpanded {
                hiddenParentIDs.insert(block.id)
            }
        }
        return result
    }

    // MARK: - Bottom Bar

    private var bottomAddBlockBar: some View {
        HStack {
            Spacer(minLength: 0)
            if isSelectionMode {
                batchSelectionBar
            } else if isKeyboardVisible {
                keyboardBar
            } else {
                addBlockMenu
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var keyboardBar: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(JournalBlockType.allCases, id: \.self) { type in
                    Button(labelForType(type)) { appendBlock(type: type) }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Block")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(LGradients.blue)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } label: {
                Text("Done")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(LGradients.blue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.36))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(LColors.glassBorder, lineWidth: 1))
    }

    private var isSelectionMode: Bool { !selectedBlockIDs.isEmpty }

    private var batchSelectionBar: some View {
        HStack(spacing: 10) {
            Button { clearBlockSelection() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text("\(selectedBlockIDs.count) Selected")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 0)

            Button { indentSelectedBlocksOut() } label: {
                Image(systemName: "decrease.indent")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button { indentSelectedBlocksIn() } label: {
                Image(systemName: "increase.indent")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button(role: .destructive) { deleteSelectedBlocks() } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.red.opacity(0.26))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.36))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(LColors.glassBorder, lineWidth: 1))
    }

    private var addBlockMenu: some View {
        Menu {
            ForEach(JournalBlockType.allCases, id: \.self) { type in
                Button(labelForType(type)) { appendBlock(type: type) }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Add Block")
            }
            .frame(maxWidth: .infinity)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(LGradients.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minWidth: 180)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(LGradients.blue, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection Mode

    private func enterSelectionMode(_ block: JournalBlock) {
        selectedBlockIDs = [block.id]
    }

    private func toggleBlockSelection(_ block: JournalBlock) {
        if selectedBlockIDs.contains(block.id) {
            selectedBlockIDs.remove(block.id)
        } else {
            selectedBlockIDs.insert(block.id)
        }
    }

    private func clearBlockSelection() { selectedBlockIDs.removeAll() }

    private func selectedBlocksInOrder() -> [JournalBlock] {
        entry.sortedBlocks.filter { selectedBlockIDs.contains($0.id) }
    }

    private func deleteSelectedBlocks() {
        let blocks = selectedBlocksInOrder()
        guard !blocks.isEmpty else { return }
        clearBlockSelection()
        for block in blocks { deleteBlock(block) }
    }

    private func indentSelectedBlocksIn() {
        let blocks = selectedBlocksInOrder()
        guard !blocks.isEmpty else { return }
        for block in blocks where canIndentBatchBlock(block) {
            block.indentLevel = min(5, block.indentLevel + 1)
            block.touch()
        }
        save()
    }

    private func indentSelectedBlocksOut() {
        let blocks = selectedBlocksInOrder()
        guard !blocks.isEmpty else { return }
        for block in blocks where canIndentBatchBlock(block) {
            block.indentLevel = max(0, block.indentLevel - 1)
            block.touch()
        }
        save()
    }

    private func canIndentBatchBlock(_ block: JournalBlock) -> Bool {
        switch block.type {
        case .paragraph, .heading1, .heading2, .heading3, .heading4, .heading5, .heading6,
             .toggleHeading1, .toggleHeading2, .toggleHeading3, .toggleHeading4, .toggleHeading5, .toggleHeading6,
             .toggle, .bulletedList, .numberedList, .checklist, .blockquote, .callout:
            return true
        case .divider, .code, .image, .table:
            return false
        }
    }

    // MARK: - Block Mutations

    private func appendBlock(type: JournalBlockType) {
        guard !isMutatingBlocks else { return }
        clearBlockSelection()

        if let focusedID = focusedBlockID,
           let focusedBlock = entry.sortedBlocks.first(where: { $0.id == focusedID }) {
            insertBlockBelow(focusedBlock, type, "")
            return
        }

        isMutatingBlocks = true
        defer { isMutatingBlocks = false }

        let newBlock = JournalBlock(
            type: type,
            text: type == .table ? JournalTableData().toJSON() : "",
            sortOrder: entry.sortedBlocks.count,
            parentBlockID: nil,
            listGroupID: type == .bulletedList || type == .numberedList || type == .checklist ? UUID() : nil,
            isExpanded: type == .toggle || type.isToggleHeading,
            indentLevel: 0,
            calloutEmoji: type == .callout ? defaultCalloutIconID : "",
            languageHint: type == .divider ? DividerStyle.line.rawValue : ""
        )
        newBlock.entry = entry
        newBlock.touch()
        if entry.blocks == nil { entry.blocks = [] }
        entry.blocks?.append(newBlock)
        entry.ensureStarterBlock()
        entry.normalizeBlockSortOrders()
        save()
    }

    private func insertBlockBelow(_ block: JournalBlock, _ type: JournalBlockType, _ initialText: String = "") {
        guard !isMutatingBlocks else { return }
        clearBlockSelection()
        isMutatingBlocks = true
        defer { isMutatingBlocks = false }

        let sorted = entry.sortedBlocks
        guard sorted.contains(where: { $0.id == block.id }) else { return }

        let insertAfterOrder = block.sortOrder

        let shouldContinueSameList = (block.type == type && block.isListBlock && type == .bulletedList)
            || (block.type == type && block.isListBlock && type == .numberedList)
            || (block.type == type && block.isListBlock && type == .checklist)

        let inheritedListGroupID: UUID? = {
            if shouldContinueSameList { return block.listGroupID }
            if type == .bulletedList || type == .numberedList || type == .checklist { return UUID() }
            return nil
        }()

        let inheritedParentBlockID: UUID? = {
            if block.isToggleBlock || block.type.isToggleHeading { return block.id }
            return block.parentBlockID
        }()

        let inheritedIndentLevel: Int = (block.isToggleBlock || block.type.isToggleHeading)
            ? block.indentLevel + 1
            : block.indentLevel

        let newBlock = JournalBlock(
            type: type,
            text: type == .table ? (initialText.isEmpty ? JournalTableData().toJSON() : initialText) : initialText,
            sortOrder: insertAfterOrder + 1,
            parentBlockID: inheritedParentBlockID,
            listGroupID: inheritedListGroupID,
            isExpanded: type == .toggle || type.isToggleHeading,
            indentLevel: inheritedIndentLevel,
            calloutEmoji: type == .callout ? defaultCalloutIconID : "",
            languageHint: type == .divider ? DividerStyle.line.rawValue : ""
        )
        newBlock.entry = entry
        newBlock.touch()
        if entry.blocks == nil { entry.blocks = [] }
        entry.blocks?.append(newBlock)

        for laterBlock in (entry.blocks ?? []) where laterBlock.id != newBlock.id && laterBlock.sortOrder > insertAfterOrder {
            laterBlock.sortOrder += 1
            laterBlock.touch()
        }

        entry.ensureStarterBlock()
        entry.normalizeBlockSortOrders()
        save()

        let newBlockID = newBlock.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NotificationCenter.default.post(name: .journalBlockRequestFocus, object: newBlockID)
        }
    }

    private func deleteBlock(_ block: JournalBlock) {
        guard !isMutatingBlocks else { return }
        isMutatingBlocks = true
        defer { isMutatingBlocks = false }

        let blockID = block.id
        selectedBlockIDs.remove(blockID)
        let blockSortOrder = block.sortOrder

        for inlineStyle in (block.inlineStyles ?? []) { modelContext.delete(inlineStyle) }

        if let index = entry.blocks?.firstIndex(where: { $0.id == blockID }) {
            entry.blocks?.remove(at: index)
        }
        modelContext.delete(block)

        if entry.blocks?.isEmpty != false {
            if entry.blocks == nil { entry.blocks = [] }
            let replacement = JournalBlock(type: .paragraph, text: "", sortOrder: 0)
            replacement.entry = entry
            replacement.touch()
            entry.blocks?.append(replacement)
        }

        entry.normalizeBlockSortOrders()
        save()

        let sorted = entry.sortedBlocks
        let focusTarget = sorted.first(where: { $0.sortOrder >= blockSortOrder }) ?? sorted.last
        if let target = focusTarget {
            let targetID = target.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NotificationCenter.default.post(name: .journalBlockRequestFocus, object: targetID)
            }
        }
    }

    private func moveBlockUp(_ block: JournalBlock) {
        guard !isMutatingBlocks else { return }
        isMutatingBlocks = true
        defer { isMutatingBlocks = false }

        let sorted = entry.sortedBlocks
        guard let index = sorted.firstIndex(where: { $0.id == block.id }), index > 0 else { return }

        let above = sorted[index - 1]
        let currentOrder = block.sortOrder
        block.sortOrder = above.sortOrder
        above.sortOrder = currentOrder
        block.touch(); above.touch()
        entry.normalizeBlockSortOrders()
        save()
    }

    private func moveBlockDown(_ block: JournalBlock) {
        guard !isMutatingBlocks else { return }
        isMutatingBlocks = true
        defer { isMutatingBlocks = false }

        let sorted = entry.sortedBlocks
        guard let index = sorted.firstIndex(where: { $0.id == block.id }), index < sorted.count - 1 else { return }

        let below = sorted[index + 1]
        let currentOrder = block.sortOrder
        block.sortOrder = below.sortOrder
        below.sortOrder = currentOrder
        block.touch(); below.touch()
        entry.normalizeBlockSortOrders()
        save()
    }

    private func transformBlock(_ block: JournalBlock, _ type: JournalBlockType) {
        guard !isMutatingBlocks else { return }
        isMutatingBlocks = true
        defer { isMutatingBlocks = false }

        block.type = type

        if type == .bulletedList || type == .numberedList || type == .checklist {
            if block.listGroupID == nil { block.listGroupID = UUID() }
        } else {
            block.listGroupID = nil
        }

        if type == .toggle || type.isToggleHeading { block.isExpanded = true }
        else if !block.isToggleBlock { block.parentBlockID = nil }

        let wasToggleChild = block.parentBlockID != nil

        switch type {
        case .callout:
            if !wasToggleChild { block.parentBlockID = nil }
            block.indentLevel = wasToggleChild ? block.indentLevel : 0
            if block.calloutEmoji.isEmpty { block.calloutEmoji = defaultCalloutIconID }
        case .divider:
            if !wasToggleChild { block.parentBlockID = nil }
            block.indentLevel = wasToggleChild ? block.indentLevel : 0
            block.text = ""; block.languageHint = DividerStyle.line.rawValue
            for s in (block.inlineStyles ?? []) { modelContext.delete(s) }
            block.inlineStyles = []
        case .code:
            if !wasToggleChild { block.parentBlockID = nil }
            block.indentLevel = wasToggleChild ? block.indentLevel : 0
            for s in (block.inlineStyles ?? []) { modelContext.delete(s) }
            block.inlineStyles = []
        case .image:
            if !wasToggleChild { block.parentBlockID = nil }
            block.indentLevel = wasToggleChild ? block.indentLevel : 0
            block.text = ""
            for s in (block.inlineStyles ?? []) { modelContext.delete(s) }
            block.inlineStyles = []
        case .paragraph, .heading1, .heading2, .heading3, .heading4, .heading5, .heading6, .blockquote:
            if !wasToggleChild { block.parentBlockID = nil }
            block.indentLevel = wasToggleChild ? block.indentLevel : 0
            block.languageHint = ""
        case .toggle, .toggleHeading1, .toggleHeading2, .toggleHeading3,
             .toggleHeading4, .toggleHeading5, .toggleHeading6:
            if !wasToggleChild { block.parentBlockID = nil }
            block.indentLevel = wasToggleChild ? block.indentLevel : 0
            block.languageHint = ""; block.isExpanded = true
        case .bulletedList, .numberedList:
            if !wasToggleChild { block.parentBlockID = nil }
            block.indentLevel = wasToggleChild ? block.indentLevel : 0
            block.languageHint = ""
        case .checklist:
            if !wasToggleChild { block.parentBlockID = nil }
            block.indentLevel = wasToggleChild ? block.indentLevel : 0
            if block.languageHint != "checked" && block.languageHint != "xmark" {
                block.languageHint = ""
            }
        case .table:
            if !wasToggleChild { block.parentBlockID = nil }
            block.indentLevel = 0
            block.text = JournalTableData().toJSON()
            for s in (block.inlineStyles ?? []) { modelContext.delete(s) }
            block.inlineStyles = []
        }

        block.touch()
        entry.normalizeBlockSortOrders()
        save()
    }

    private var defaultCalloutIconID: String { "asset:sparkle" }

    private func labelForType(_ type: JournalBlockType) -> String {
        switch type {
        case .paragraph:     return "Paragraph"
        case .heading1:      return "Heading 1"
        case .heading2:      return "Heading 2"
        case .heading3:      return "Heading 3"
        case .heading4:      return "Heading 4"
        case .heading5:      return "Heading 5"
        case .heading6:      return "Heading 6"
        case .toggleHeading1: return "Toggle H1"
        case .toggleHeading2: return "Toggle H2"
        case .toggleHeading3: return "Toggle H3"
        case .toggleHeading4: return "Toggle H4"
        case .toggleHeading5: return "Toggle H5"
        case .toggleHeading6: return "Toggle H6"
        case .toggle:        return "Toggle"
        case .bulletedList:  return "Bulleted List"
        case .numberedList:  return "Numbered List"
        case .checklist:     return "Checklist"
        case .blockquote:    return "Blockquote"
        case .callout:       return "Callout"
        case .divider:       return "Divider"
        case .code:          return "Code Block"
        case .image:         return "Image"
        case .table:         return "Table"
        }
    }

    private func reorderBlockToIndex(source: JournalBlock, toIndex: Int) {
        guard !isMutatingBlocks else { return }
        isMutatingBlocks = true
        defer { isMutatingBlocks = false }

        let sorted = entry.sortedBlocks
        guard let fromIndex = sorted.firstIndex(where: { $0.id == source.id }) else { return }

        var reordered = sorted
        let destination = toIndex > fromIndex ? toIndex + 1 : toIndex
        reordered.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: destination)

        for (i, block) in reordered.enumerated() {
            block.sortOrder = i
            block.touch()
        }

        entry.normalizeBlockSortOrders()
        save()
    }

    private func save() {
        do { try modelContext.save() } catch { print("Failed to save journal blocks: \(error)") }
    }
}


// MARK: - Page Tap Overlay

struct PageSheetTapOverlay: View {
    let onTap: (CGPoint) -> Void

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    onTap(location)
                }
        }
    }
}

// MARK: - Drop Zone

struct BlockDropZone: View {
    let index: Int
    @Binding var dragOverIndex: Int?

    private var isActive: Bool { dragOverIndex == index }

    var body: some View {
        ZStack {
            if isActive {
                Capsule()
                    .fill(LGradients.blue)
                    .frame(height: 3)
                    .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: isActive ? 16 : 0)
        .contentShape(Rectangle())
    }
}

// MARK: - Indexed Drop Delegate

struct IndexedDropDelegate: DropDelegate {
    let index: Int
    @Binding var draggingBlock: JournalBlock?
    @Binding var dragOverIndex: Int?
    let visibleBlocks: [JournalBlock]
    let onMove: (JournalBlock, Int) -> Void

    func dropEntered(info: DropInfo) { dragOverIndex = index }
    func dropUpdated(info: DropInfo) -> DropProposal? { dragOverIndex = index; return DropProposal(operation: .move) }
    func dropExited(info: DropInfo) { if dragOverIndex == index { dragOverIndex = nil } }
    func performDrop(info: DropInfo) -> Bool {
        guard let source = draggingBlock else { draggingBlock = nil; dragOverIndex = nil; return false }
        onMove(source, index)
        draggingBlock = nil; dragOverIndex = nil
        return true
    }
}
