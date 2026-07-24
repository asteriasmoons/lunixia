//
//  LunixiaStickyNoteWidget.swift
//  LunixiaWidgets
//

import AppIntents
import CoreText
import SwiftUI
import WidgetKit

// MARK: - Snapshot

struct LunixiaStickyNoteWidgetChecklistItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var isCompleted: Bool
}

struct LunixiaStickyNoteWidgetNote: Codable, Identifiable, Equatable {
    var id: UUID
    var content: String
    var colorHex: String
    var checklistItems: [LunixiaStickyNoteWidgetChecklistItem]
    var fontID: String
    var tabName: String
    var label: String
    var label2: String
    var isPinned: Bool
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case colorHex
        case checklistItems
        case fontID
        case tabName
        case label
        case label2
        case isPinned
        case updatedAt
    }

    init(
        id: UUID,
        content: String,
        colorHex: String,
        checklistItems: [LunixiaStickyNoteWidgetChecklistItem],
        fontID: String,
        tabName: String,
        label: String,
        label2: String,
        isPinned: Bool,
        updatedAt: Date
    ) {
        self.id = id
        self.content = content
        self.colorHex = colorHex
        self.checklistItems = checklistItems
        self.fontID = fontID
        self.tabName = tabName
        self.label = label
        self.label2 = label2
        self.isPinned = isPinned
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        checklistItems = try container.decodeIfPresent([LunixiaStickyNoteWidgetChecklistItem].self, forKey: .checklistItems) ?? []
        fontID = try container.decodeIfPresent(String.self, forKey: .fontID) ?? "system"
        tabName = try container.decodeIfPresent(String.self, forKey: .tabName) ?? "All Notes"
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        label2 = try container.decodeIfPresent(String.self, forKey: .label2) ?? ""
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

struct LunixiaStickyNoteWidgetSnapshot: Codable, Equatable {
    var tabs: [String]
    var notes: [LunixiaStickyNoteWidgetNote]
    var lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case tabs
        case notes
        case lastUpdated
    }

    init(tabs: [String], notes: [LunixiaStickyNoteWidgetNote], lastUpdated: Date) {
        self.tabs = tabs
        self.notes = notes
        self.lastUpdated = lastUpdated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notes = try container.decode([LunixiaStickyNoteWidgetNote].self, forKey: .notes)
        let decodedTabs = try container.decodeIfPresent([String].self, forKey: .tabs) ?? []
        let noteTabs = notes.map(\.tabName)
        var mergedTabs: [String] = decodedTabs.isEmpty ? ["All Notes"] : decodedTabs
        for tab in noteTabs where !mergedTabs.contains(tab) {
            mergedTabs.append(tab)
        }
        tabs = mergedTabs
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }
}

enum LunixiaStickyNoteWidgetStore {
    static let appGroupID = "group.com.asteriasmoons.Lunixia"
    static let snapshotKey = "lunixiaStickyNoteWidgetSnapshot"
    private static let checklistToggleRequestsKey = "lunixiaStickyNoteChecklistToggleRequests"

    struct ChecklistToggleRequest: Codable, Equatable {
        var noteID: UUID
        var itemID: UUID
        var isCompleted: Bool
        var createdAt: Date
    }

    static func read() -> LunixiaStickyNoteWidgetSnapshot {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: snapshotKey),
            let decoded = try? JSONDecoder().decode(LunixiaStickyNoteWidgetSnapshot.self, from: data)
        else { return placeholder }

        return decoded
    }

    static var placeholder: LunixiaStickyNoteWidgetSnapshot {
        LunixiaStickyNoteWidgetSnapshot(
            tabs: ["All Notes"],
            notes: [
                LunixiaStickyNoteWidgetNote(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
                    content: "Choose a sticky note to keep nearby.",
                    colorHex: "#6B4CDE",
                    checklistItems: [
                        LunixiaStickyNoteWidgetChecklistItem(
                            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
                            title: "Tap and hold to edit widget",
                            isCompleted: false
                        )
                    ],
                    fontID: "rounded",
                    tabName: "All Notes",
                    label: "",
                    label2: "",
                    isPinned: false,
                    updatedAt: Date()
                )
            ],
            lastUpdated: Date()
        )
    }

    static func notes(in tabName: String?) -> [LunixiaStickyNoteWidgetNote] {
        let notes = read().notes
        guard let tabName, !tabName.isEmpty else { return notes }
        return notes.filter { $0.tabName == tabName }
    }

    static func note(id: UUID?, in tabName: String?) -> LunixiaStickyNoteWidgetNote? {
        let filteredNotes = notes(in: tabName)
        let notes = filteredNotes.isEmpty ? read().notes : filteredNotes
        guard let id else { return notes.first }
        return notes.first { $0.id == id } ?? notes.first
    }

    static func toggleChecklistItem(noteID: UUID, itemID: UUID) {
        var snapshot = read()
        guard let noteIndex = snapshot.notes.firstIndex(where: { $0.id == noteID }),
              let itemIndex = snapshot.notes[noteIndex].checklistItems.firstIndex(where: { $0.id == itemID })
        else { return }

        snapshot.notes[noteIndex].checklistItems[itemIndex].isCompleted.toggle()
        snapshot.notes[noteIndex].updatedAt = Date()
        snapshot.lastUpdated = Date()

        let isCompleted = snapshot.notes[noteIndex].checklistItems[itemIndex].isCompleted
        write(snapshot)
        enqueueToggle(
            ChecklistToggleRequest(
                noteID: noteID,
                itemID: itemID,
                isCompleted: isCompleted,
                createdAt: Date()
            )
        )
        WidgetCenter.shared.reloadTimelines(ofKind: "LunixiaStickyNoteWidget")
    }

    private static func write(_ snapshot: LunixiaStickyNoteWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: appGroupID)?.set(data, forKey: snapshotKey)
    }

    private static func enqueueToggle(_ request: ChecklistToggleRequest) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        var requests = readToggleRequests(from: defaults)
        requests.removeAll { $0.noteID == request.noteID && $0.itemID == request.itemID }
        requests.append(request)

        guard let data = try? JSONEncoder().encode(requests) else { return }
        defaults.set(data, forKey: checklistToggleRequestsKey)
    }

    private static func readToggleRequests(from defaults: UserDefaults) -> [ChecklistToggleRequest] {
        guard let data = defaults.data(forKey: checklistToggleRequestsKey),
              let decoded = try? JSONDecoder().decode([ChecklistToggleRequest].self, from: data)
        else { return [] }
        return decoded
    }
}

// MARK: - Checklist Toggle Intent

struct ToggleStickyNoteChecklistItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Checklist Item"
    static var description = IntentDescription("Marks a sticky note checklist item complete or incomplete.")
    static var openAppWhenRun = false

    @Parameter(title: "Note ID")
    var noteID: String

    @Parameter(title: "Checklist Item ID")
    var itemID: String

    init() {
        noteID = ""
        itemID = ""
    }

    init(noteID: UUID, itemID: UUID) {
        self.noteID = noteID.uuidString
        self.itemID = itemID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let noteUUID = UUID(uuidString: noteID),
              let itemUUID = UUID(uuidString: itemID)
        else { return .result() }

        LunixiaStickyNoteWidgetStore.toggleChecklistItem(noteID: noteUUID, itemID: itemUUID)
        return .result()
    }
}

// MARK: - App Intent Configuration

struct StickyNoteTabEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Note Tab")
    static var defaultQuery = StickyNoteTabEntityQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct StickyNoteTabEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [StickyNoteTabEntity] {
        LunixiaStickyNoteWidgetStore.read().tabs
            .filter { identifiers.contains($0) }
            .map { StickyNoteTabEntity(id: $0, name: $0) }
    }

    func suggestedEntities() async throws -> [StickyNoteTabEntity] {
        LunixiaStickyNoteWidgetStore.read().tabs
            .map { StickyNoteTabEntity(id: $0, name: $0) }
    }

    func defaultResult() async -> StickyNoteTabEntity? {
        LunixiaStickyNoteWidgetStore.read().tabs.first
            .map { StickyNoteTabEntity(id: $0, name: $0) }
    }
}

struct StickyNoteEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Sticky Note")
    static var defaultQuery = StickyNoteEntityQuery()

    let id: UUID
    let title: String
    let tabName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct StickyNoteEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [StickyNoteEntity] {
        let notes = LunixiaStickyNoteWidgetStore.read().notes
        return notes
            .filter { identifiers.contains($0.id) }
            .map(StickyNoteEntity.init(note:))
    }

    func suggestedEntities() async throws -> [StickyNoteEntity] {
        LunixiaStickyNoteWidgetStore.read().notes.map(StickyNoteEntity.init(note:))
    }

    func defaultResult() async -> StickyNoteEntity? {
        LunixiaStickyNoteWidgetStore.read().notes.first.map(StickyNoteEntity.init(note:))
    }
}

struct StickyNoteOptionsProvider: DynamicOptionsProvider {
    @IntentParameterDependency<StickyNoteConfigurationIntent>(\.$tab)
    var intent

    func results() async throws -> [StickyNoteEntity] {
        LunixiaStickyNoteWidgetStore.notes(in: intent?.tab.name)
            .map(StickyNoteEntity.init(note:))
    }

    func defaultResult() async -> StickyNoteEntity? {
        LunixiaStickyNoteWidgetStore.notes(in: intent?.tab.name)
            .first
            .map(StickyNoteEntity.init(note:))
    }
}

extension StickyNoteEntity {
    init(note: LunixiaStickyNoteWidgetNote) {
        let trimmed = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let checklistTitle = note.checklistItems
            .map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        self.id = note.id
        self.title = trimmed.isEmpty ? (checklistTitle ?? "Empty Note") : trimmed
        self.tabName = note.tabName
    }
}

struct StickyNoteConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Sticky Note"
    static var description = IntentDescription("Choose a note for this widget.")

    @Parameter(title: "Tab")
    var tab: StickyNoteTabEntity?

    @Parameter(title: "Note", optionsProvider: StickyNoteOptionsProvider())
    var note: StickyNoteEntity?

    init() {
        self.tab = nil
        self.note = nil
    }

    init(tab: StickyNoteTabEntity? = nil, note: StickyNoteEntity? = nil) {
        self.tab = tab
        self.note = note
    }
}

// MARK: - Timeline

struct LunixiaStickyNoteWidgetEntry: TimelineEntry {
    let date: Date
    let selectedNoteID: UUID?
    let note: LunixiaStickyNoteWidgetNote?
    let lastUpdated: Date
}

struct LunixiaStickyNoteWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LunixiaStickyNoteWidgetEntry {
        let snapshot = LunixiaStickyNoteWidgetStore.read()
        return LunixiaStickyNoteWidgetEntry(
            date: Date(),
            selectedNoteID: snapshot.notes.first?.id,
            note: snapshot.notes.first,
            lastUpdated: snapshot.lastUpdated
        )
    }

    func snapshot(for configuration: StickyNoteConfigurationIntent, in context: Context) async -> LunixiaStickyNoteWidgetEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: StickyNoteConfigurationIntent, in context: Context) async -> Timeline<LunixiaStickyNoteWidgetEntry> {
        let entry = entry(for: configuration)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func entry(for configuration: StickyNoteConfigurationIntent) -> LunixiaStickyNoteWidgetEntry {
        let snapshot = LunixiaStickyNoteWidgetStore.read()
        let selectedID = configuration.note?.id
        let selectedTab = configuration.tab?.name
        return LunixiaStickyNoteWidgetEntry(
            date: Date(),
            selectedNoteID: selectedID,
            note: LunixiaStickyNoteWidgetStore.note(id: selectedID, in: selectedTab),
            lastUpdated: snapshot.lastUpdated
        )
    }
}

// MARK: - Fonts

private enum StickyNoteWidgetFontOption: String {
    case system
    case rounded
    case serif
    case twoSixOnePinky
    case beautifulRainbow
    case childowEveryday
    case chunkyBear
    case foxLollipop
    case hachiMaruPop
    case inLove
    case jellyFoxHighlight
    case liveOnTheMoon
    case loveMonday
    case mightyFineDemibold
    case quirkyLoving
    case sabrinaLovely
    case soulDreams
    case sugarDonutHeart

    var postScriptName: String? {
        switch self {
        case .system, .rounded, .serif:
            return nil
        case .twoSixOnePinky:
            return "PinkyRegular"
        case .beautifulRainbow:
            return "BeautifulRainbow"
        case .childowEveryday:
            return "ChildowEveryday"
        case .chunkyBear:
            return "ChunkyBear"
        case .foxLollipop:
            return "FoxLollipopRegular"
        case .hachiMaruPop:
            return "HachiMaruPop-Regular"
        case .inLove:
            return "InLoveRegular"
        case .jellyFoxHighlight:
            return "JellyFoxHighlight"
        case .liveOnTheMoon:
            return "LiveonTheMoon"
        case .loveMonday:
            return "LoveMonday"
        case .mightyFineDemibold:
            return "ZPMightyFineDemibold"
        case .quirkyLoving:
            return "QuirkyLoving"
        case .sabrinaLovely:
            return "SabrinaLovely"
        case .soulDreams:
            return "SoulDreams"
        case .sugarDonutHeart:
            return "SugarDonutHeart"
        }
    }

    var fileName: String? {
        switch self {
        case .system, .rounded, .serif:
            return nil
        case .twoSixOnePinky:
            return "261 Pinky.otf"
        case .beautifulRainbow:
            return "Beautiful Rainbow Font by Dani 7NTypes.otf"
        case .childowEveryday:
            return "Childow Everyday.otf"
        case .chunkyBear:
            return "Chunky Bear.otf"
        case .foxLollipop:
            return "Fox Lollipop.otf"
        case .hachiMaruPop:
            return "HachiMaruPop-Regular.ttf"
        case .inLove:
            return "Inlove.otf"
        case .jellyFoxHighlight:
            return "Jelly Fox Highlight.otf"
        case .liveOnTheMoon:
            return "Live On The Moon.otf"
        case .loveMonday:
            return "Love Monday.otf"
        case .mightyFineDemibold:
            return "Mighty Fine Demibold.otf"
        case .quirkyLoving:
            return "Quirky Loving.otf"
        case .sabrinaLovely:
            return "Sabrina Lovely.otf"
        case .soulDreams:
            return "Soul Dreams.otf"
        case .sugarDonutHeart:
            return "Sugar Donut Heart.otf"
        }
    }

    static func option(for id: String) -> StickyNoteWidgetFontOption {
        StickyNoteWidgetFontOption(rawValue: id) ?? .system
    }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        StickyNoteWidgetFontRegistrar.registerFontsIfNeeded()

        switch self {
        case .system:
            return .system(size: size, weight: weight)
        case .rounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        default:
            if let postScriptName {
                return .custom(postScriptName, size: size).weight(weight)
            }
            return .system(size: size, weight: weight)
        }
    }
}

private enum StickyNoteWidgetFontRegistrar {
    private static var didRegister = false

    static func registerFontsIfNeeded() {
        guard !didRegister else { return }
        didRegister = true

        for option in [
            StickyNoteWidgetFontOption.twoSixOnePinky,
            .beautifulRainbow,
            StickyNoteWidgetFontOption.childowEveryday,
            .chunkyBear,
            .foxLollipop,
            .hachiMaruPop,
            .inLove,
            .jellyFoxHighlight,
            .liveOnTheMoon,
            .loveMonday,
            .mightyFineDemibold,
            .quirkyLoving,
            .sabrinaLovely,
            .soulDreams,
            .sugarDonutHeart
        ] {
            guard let fileName = option.fileName else { continue }
            let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: fileName, withExtension: nil)
            guard let url else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

// MARK: - Widget View

struct LunixiaStickyNoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LunixiaStickyNoteWidgetEntry

    private var note: LunixiaStickyNoteWidgetNote? { entry.note }
    private var noteColor: Color { Color(lunixiaHex: note?.colorHex ?? "#6B4CDE") }
    private var fontOption: StickyNoteWidgetFontOption {
        StickyNoteWidgetFontOption.option(for: note?.fontID ?? "system")
    }

    var body: some View {
        ZStack {
            noteColor

            LinearGradient(
                colors: [
                    Color.white.opacity(0.22),
                    Color.white.opacity(0.05),
                    Color.black.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let note {
                switch family {
                case .systemSmall:
                    smallNoteContent(note)
                        .padding(widgetPadding)
                        .unredacted()
                case .systemMedium:
                    mediumNoteContent(note)
                        .padding(widgetPadding)
                        .unredacted()
                default:
                    noteContent(note)
                        .padding(widgetPadding)
                }
            } else {
                emptyContent
                    .padding(widgetPadding)
            }
        }
        .containerBackground(for: .widget) {
            noteColor
        }
    }

    private func smallNoteContent(_ note: LunixiaStickyNoteWidgetNote) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            header(note)

            VStack(alignment: .leading, spacing: 6) {
                if note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && note.checklistItems.isEmpty {
                    Text("Empty note")
                        .font(fontOption.font(size: 13))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                } else {
                    if !note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(note.content)
                            .font(fontOption.font(size: 13))
                            .foregroundStyle(.white)
                            .lineSpacing(2)
                            .lineLimit(note.checklistItems.isEmpty ? 5 : 3)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    checklist(
                        note.checklistItems,
                        noteID: note.id,
                        limit: note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 3 : 1,
                        circleSize: 14,
                        fontSize: 11,
                        itemLineLimit: 2,
                        rowSpacing: 4,
                        itemSpacing: 6
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func mediumNoteContent(_ note: LunixiaStickyNoteWidgetNote) -> some View {
        let trimmedContent = note.content.trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 9) {
            header(note)

            VStack(alignment: .leading, spacing: 8) {
                if trimmedContent.isEmpty && note.checklistItems.isEmpty {
                    Text("Empty note")
                        .font(fontOption.font(size: 14))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                } else {
                    if !trimmedContent.isEmpty {
                        Text(note.content)
                            .font(fontOption.font(size: 14))
                            .foregroundStyle(.white)
                            .lineSpacing(2)
                            .lineLimit(5)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.80)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(2)
                    }

                    checklist(
                        note.checklistItems,
                        noteID: note.id,
                        limit: trimmedContent.isEmpty ? 4 : 1,
                        circleSize: 17,
                        fontSize: 12,
                        itemLineLimit: 2,
                        rowSpacing: 7,
                        itemSpacing: 8
                    )
                    .layoutPriority(trimmedContent.isEmpty ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            footer(note)
                .layoutPriority(-1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func noteContent(_ note: LunixiaStickyNoteWidgetNote) -> some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 7 : 10) {
            header(note)

            VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 9) {
                if note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && note.checklistItems.isEmpty {
                    Text("Empty note")
                        .font(fontOption.font(size: contentFontSize))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(2)
                } else {
                    if !note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(note.content)
                            .font(fontOption.font(size: contentFontSize))
                            .foregroundStyle(.white)
                            .lineSpacing(2)
                            .lineLimit(contentLineLimit)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.80)
                    }

                    checklist(note.checklistItems, noteID: note.id)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if family != .systemSmall {
                footer(note)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func header(_ note: LunixiaStickyNoteWidgetNote) -> some View {
        HStack(spacing: 7) {
            Image("starnote")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: family == .systemSmall ? 15 : 18, height: family == .systemSmall ? 15 : 18)
                .foregroundStyle(LGradients.header)

            Text(headerTitle(note))
                .font(.system(size: family == .systemSmall ? 11 : 13, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.70)

            Spacer(minLength: 0)
        }
    }

    private func checklist(_ items: [LunixiaStickyNoteWidgetChecklistItem], noteID: UUID) -> some View {
        checklist(
            items,
            noteID: noteID,
            limit: checklistLimit,
            circleSize: family == .systemSmall ? 14 : 17,
            fontSize: checklistFontSize,
            itemLineLimit: checklistItemLineLimit,
            rowSpacing: family == .systemSmall ? 4 : 7,
            itemSpacing: family == .systemSmall ? 6 : 8
        )
    }

    private func checklist(
        _ items: [LunixiaStickyNoteWidgetChecklistItem],
        noteID: UUID,
        limit: Int,
        circleSize: CGFloat,
        fontSize: CGFloat,
        itemLineLimit: Int,
        rowSpacing: CGFloat,
        itemSpacing: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(Array(items.prefix(limit))) { item in
                HStack(alignment: .top, spacing: itemSpacing) {
                    Button(intent: ToggleStickyNoteChecklistItemIntent(noteID: noteID, itemID: item.id)) {
                        StickyNoteWidgetChecklistCircle(
                            isCompleted: item.isCompleted,
                            size: circleSize
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 1)

                    Text(item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Checklist item" : item.title)
                        .font(fontOption.font(size: fontSize))
                        .foregroundStyle(.white)
                        .strikethrough(item.isCompleted, color: Color.white.opacity(0.72))
                        .lineLimit(itemLineLimit)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func footer(_ note: LunixiaStickyNoteWidgetNote) -> some View {
        HStack(spacing: 6) {
            ForEach(activeLabels(note).prefix(family == .systemSmall ? 1 : 2), id: \.self) { label in
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.22))
                            .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.16), lineWidth: 1))
                    )
            }

            Spacer(minLength: 0)
        }
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image("linedpages")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(LGradients.header)

            Text("No sticky note yet")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Create a note in Lunixia.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func headerTitle(_ note: LunixiaStickyNoteWidgetNote) -> String {
        if note.isPinned { return "Pinned Note" }
        if let label = activeLabels(note).first { return label }
        return "Sticky Note"
    }

    private func activeLabels(_ note: LunixiaStickyNoteWidgetNote) -> [String] {
        [note.label, note.label2]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var widgetPadding: CGFloat {
        switch family {
        case .systemSmall: return 16
        case .systemMedium: return 18
        default: return 20
        }
    }

    private var contentFontSize: CGFloat {
        switch family {
        case .systemSmall: return 13
        case .systemMedium: return 14
        default: return 16
        }
    }

    private var checklistFontSize: CGFloat {
        switch family {
        case .systemSmall: return 11
        case .systemMedium: return 12
        default: return 14
        }
    }

    private var contentLineLimit: Int {
        switch family {
        case .systemSmall: return 4
        case .systemMedium: return 4
        default: return 8
        }
    }

    private var checklistLimit: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        default: return 8
        }
    }

    private var checklistItemLineLimit: Int {
        switch family {
        case .systemSmall: return 2
        case .systemMedium: return 2
        default: return 3
        }
    }
}

private struct StickyNoteWidgetChecklistCircle: View {
    let isCompleted: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isCompleted ? AnyShapeStyle(Color.clear) : AnyShapeStyle(LGradients.header),
                    lineWidth: max(1.4, size * 0.12)
                )
                .background(
                    Circle()
                        .fill(isCompleted ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(Color.clear))
                )

            if isCompleted {
                Image("checkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: size * 0.48, height: size * 0.48)
            }
        }
        .frame(width: size, height: size)
    }
}

struct LunixiaStickyNoteWidget: Widget {
    let kind = "LunixiaStickyNoteWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: StickyNoteConfigurationIntent.self,
            provider: LunixiaStickyNoteWidgetProvider()
        ) { entry in
            LunixiaStickyNoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Sticky Note")
        .description("Keep a selected Lunixia note on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
