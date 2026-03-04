import SwiftUI
import Combine
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
import PencilKit
import PhotosUI
#endif

#if canImport(AppKit)
import AppKit
#endif

// ============================================================
// MARK: - Platform Abstractions
// ============================================================

#if canImport(UIKit)
typealias PlatformColor = UIColor
typealias PlatformImage = UIImage
typealias PlatformFont = UIFont
#elseif canImport(AppKit)
typealias PlatformColor = NSColor
typealias PlatformImage = NSImage
typealias PlatformFont = NSFont
#endif


// ============================================================
// MARK: - Data Models
// ============================================================

struct CodableColor: Codable, Equatable {
    var red: Double = 0
    var green: Double = 0
    var blue: Double = 0
    var alpha: Double = 1
    var color: Color { Color(red: red, green: green, blue: blue, opacity: alpha) }

    static let white = CodableColor(red: 1, green: 1, blue: 1)
    static let black = CodableColor(red: 0, green: 0, blue: 0)
    static let darkGray = CodableColor(red: 0.2, green: 0.2, blue: 0.2)

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    init(color: Color) {
        let c = PlatformColor(color)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        #if canImport(UIKit)
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        let converted = c.usingColorSpace(.sRGB) ?? c
        r = converted.redComponent; g = converted.greenComponent; b = converted.blueComponent; a = converted.alphaComponent
        #endif
        self.red = Double(r); self.green = Double(g); self.blue = Double(b); self.alpha = Double(a)
    }
}

struct AppSettings: Codable, Equatable {
    var fontDesign: String = "rounded"
    var questionFontSize: CGFloat = 22
    var answerFontSize: CGFloat = 26
    var questionColor: CodableColor = .darkGray
    var answerColor: CodableColor = .white
    var toolbarActions: [String] = ["search", "edit", "add"]
    var backgroundTheme: String = "blush"
    var iCloudSync: Bool = false

    var resolvedDesign: Font.Design {
        switch fontDesign {
        case "serif": return .serif
        case "monospaced": return .monospaced
        case "default": return .default
        default: return .rounded
        }
    }

    static let allActions: [(id: String, label: String, icon: String)] = [
        ("search", "Search", "magnifyingglass"),
        ("edit", "Edit Card", "pencil.circle"),
        ("shuffle", "Shuffle", "shuffle"),
        ("filter", "Filter Tags", "tag"),
        ("list", "All Cards", "list.bullet.rectangle"),
        ("add", "Add Card", "plus.circle.fill"),
        ("export", "Export", "square.and.arrow.up"),
        ("settings", "Settings", "gearshape"),
        ("delete", "Delete Card", "trash"),
    ]

    enum CodingKeys: String, CodingKey {
        case fontDesign, questionFontSize, answerFontSize, questionColor, answerColor, toolbarActions, backgroundTheme, iCloudSync
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fontDesign = (try? c.decode(String.self, forKey: .fontDesign)) ?? "rounded"
        questionFontSize = (try? c.decode(CGFloat.self, forKey: .questionFontSize)) ?? 22
        answerFontSize = (try? c.decode(CGFloat.self, forKey: .answerFontSize)) ?? 26
        questionColor = (try? c.decode(CodableColor.self, forKey: .questionColor)) ?? .darkGray
        answerColor = (try? c.decode(CodableColor.self, forKey: .answerColor)) ?? .white
        toolbarActions = (try? c.decode([String].self, forKey: .toolbarActions)) ?? ["search", "edit", "add"]
        backgroundTheme = (try? c.decode(String.self, forKey: .backgroundTheme)) ?? "blush"
        iCloudSync = (try? c.decode(Bool.self, forKey: .iCloudSync)) ?? false
    }
}

struct BGTheme {
    let id: String
    let name: String
    let colors: [Color]

    static let all: [BGTheme] = [
        BGTheme(id: "blush", name: "Blush", colors: [CuteTheme.softPink, CuteTheme.cream, CuteTheme.sky.opacity(0.5)]),
        BGTheme(id: "sunset", name: "Sunset", colors: [Color(red: 1.0, green: 0.92, blue: 0.88), Color(red: 0.98, green: 0.86, blue: 0.82), Color(red: 0.94, green: 0.82, blue: 0.88)]),
        BGTheme(id: "ocean", name: "Ocean", colors: [Color(red: 0.88, green: 0.94, blue: 0.98), Color(red: 0.82, green: 0.90, blue: 0.96), Color(red: 0.90, green: 0.94, blue: 0.98)]),
        BGTheme(id: "lavender", name: "Lavender", colors: [Color(red: 0.94, green: 0.90, blue: 0.98), Color(red: 0.96, green: 0.93, blue: 0.99), Color(red: 0.92, green: 0.90, blue: 0.97)]),
        BGTheme(id: "mint", name: "Mint", colors: [Color(red: 0.90, green: 0.97, blue: 0.93), Color(red: 0.93, green: 0.98, blue: 0.94), Color(red: 0.88, green: 0.96, blue: 0.94)]),
        BGTheme(id: "peach", name: "Peach", colors: [Color(red: 0.99, green: 0.93, blue: 0.88), Color(red: 1.0, green: 0.95, blue: 0.90), Color(red: 0.98, green: 0.92, blue: 0.86)]),
        BGTheme(id: "snow", name: "Snow", colors: [Color(red: 0.96, green: 0.96, blue: 0.97), Color(red: 0.98, green: 0.98, blue: 0.99), Color(red: 0.95, green: 0.95, blue: 0.96)]),
        BGTheme(id: "midnight", name: "Midnight", colors: [Color(red: 0.12, green: 0.12, blue: 0.16), Color(red: 0.16, green: 0.14, blue: 0.20), Color(red: 0.10, green: 0.10, blue: 0.14)]),
    ]

    static func colors(for id: String) -> [Color] {
        all.first { $0.id == id }?.colors ?? all[0].colors
    }

    static func isDark(_ id: String) -> Bool {
        id == "midnight"
    }
}

// Theme-aware colors that adapt to light/dark backgrounds
struct ThemeColors {
    let settings: AppSettings

    var isDark: Bool { BGTheme.isDark(settings.backgroundTheme) }

    var primaryText: Color { isDark ? .white : .primary }
    var secondaryText: Color { isDark ? .white.opacity(0.7) : CuteTheme.subtle }
    var deckRowBG: Color { isDark ? .white.opacity(0.1) : .white.opacity(0.9) }
    var deckRowShadow: Color { isDark ? .clear : CuteTheme.pink.opacity(0.15) }
    var accentText: Color { isDark ? CuteTheme.pink : CuteTheme.accent.opacity(0.7) }
    var chevron: Color { isDark ? .white.opacity(0.3) : .gray.opacity(0.3) }
    var cardCount: Color { isDark ? .white.opacity(0.5) : CuteTheme.subtle.opacity(0.7) }
    var emptyText: Color { isDark ? .white.opacity(0.6) : CuteTheme.subtle }
    var dotInactive: Color { isDark ? .white.opacity(0.3) : CuteTheme.pink.opacity(0.45) }
    var dotOverflow: Color { isDark ? .white.opacity(0.2) : CuteTheme.pink.opacity(0.3) }
    var filterBarText: Color { isDark ? CuteTheme.pink : CuteTheme.accent }
}

struct Flashcard: Identifiable, Codable {
    var id = UUID()
    var question: String
    var answer: String
    var notes: String = ""
    var tags: [String] = []
    var questionRTF: Data? = nil
    var answerRTF: Data? = nil
    var notesRTF: Data? = nil
    var questionImageData: Data? = nil
    var answerImageData: Data? = nil
    var questionDoodleData: Data? = nil
    var answerDoodleData: Data? = nil
    var createdAt: Date = Date()

    // Migration: old single fields
    var imageData: Data? {
        get { questionImageData }
        set { questionImageData = newValue }
    }
    var doodleData: Data? {
        get { questionDoodleData }
        set { questionDoodleData = newValue }
    }

    private enum CodingKeys: String, CodingKey {
        case id, question, answer, notes, tags
        case questionRTF, answerRTF, notesRTF
        case questionImageData, answerImageData
        case questionDoodleData, answerDoodleData
        case createdAt
        case imageData, doodleData
    }

    init(id: UUID = UUID(), question: String, answer: String, notes: String = "", tags: [String] = [],
         questionRTF: Data? = nil, answerRTF: Data? = nil, notesRTF: Data? = nil,
         questionImageData: Data? = nil, answerImageData: Data? = nil,
         questionDoodleData: Data? = nil, answerDoodleData: Data? = nil,
         createdAt: Date = Date()) {
        self.id = id; self.question = question; self.answer = answer; self.notes = notes; self.tags = tags
        self.questionRTF = questionRTF; self.answerRTF = answerRTF; self.notesRTF = notesRTF
        self.questionImageData = questionImageData; self.answerImageData = answerImageData
        self.questionDoodleData = questionDoodleData; self.answerDoodleData = answerDoodleData
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        question = try c.decode(String.self, forKey: .question)
        answer = try c.decode(String.self, forKey: .answer)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        questionRTF = try c.decodeIfPresent(Data.self, forKey: .questionRTF)
        answerRTF = try c.decodeIfPresent(Data.self, forKey: .answerRTF)
        notesRTF = try c.decodeIfPresent(Data.self, forKey: .notesRTF)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        questionImageData = try c.decodeIfPresent(Data.self, forKey: .questionImageData) ?? c.decodeIfPresent(Data.self, forKey: .imageData)
        answerImageData = try c.decodeIfPresent(Data.self, forKey: .answerImageData)
        questionDoodleData = try c.decodeIfPresent(Data.self, forKey: .questionDoodleData) ?? c.decodeIfPresent(Data.self, forKey: .doodleData)
        answerDoodleData = try c.decodeIfPresent(Data.self, forKey: .answerDoodleData)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(question, forKey: .question)
        try c.encode(answer, forKey: .answer)
        try c.encode(notes, forKey: .notes)
        try c.encode(tags, forKey: .tags)
        try c.encodeIfPresent(questionRTF, forKey: .questionRTF)
        try c.encodeIfPresent(answerRTF, forKey: .answerRTF)
        try c.encodeIfPresent(notesRTF, forKey: .notesRTF)
        try c.encodeIfPresent(questionImageData, forKey: .questionImageData)
        try c.encodeIfPresent(answerImageData, forKey: .answerImageData)
        try c.encodeIfPresent(questionDoodleData, forKey: .questionDoodleData)
        try c.encodeIfPresent(answerDoodleData, forKey: .answerDoodleData)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

struct Deck: Identifiable, Codable {
    var id = UUID()
    var name: String
    var cards: [Flashcard] = []
    var createdAt: Date = Date()
}


// ============================================================
// MARK: - Data Store (with iCloud Sync)
// ============================================================

class DataStore: ObservableObject {
    @Published var decks: [Deck] = [] { didSet { save() } }
    @Published var appTitle: String = "\u{1F338} Flashcards" { didSet { UserDefaults.standard.set(appTitle, forKey: "app_title") } }
    @Published var settings: AppSettings = AppSettings() { didSet { saveSettings() } }
    @Published var pendingDeckNav: UUID? = nil
    @Published var pendingCardID: UUID? = nil

    private let decksKey = "saved_decks_v3"
    private var iCloudObserver: NSObjectProtocol? = nil

    init() {
        if let t = UserDefaults.standard.string(forKey: "app_title") { appTitle = t }
        loadSettings()
        loadDecks()
        if decks.isEmpty { createSampleDeck() }
        setupICloudObserver()
    }

    deinit {
        if let obs = iCloudObserver { NotificationCenter.default.removeObserver(obs) }
    }

    func createSampleDeck() {
        let cards: [Flashcard] = [
            Flashcard(question: "What is the capital of Japan?", answer: "Tokyo", notes: "Tokyo is the most populous metropolitan area in the world with over 37 million people.", tags: ["geography", "asia"]),
            Flashcard(question: "What is photosynthesis?", answer: "The process plants use to convert sunlight into energy", notes: "6CO\u{2082} + 6H\u{2082}O \u{2192} C\u{2086}H\u{2081}\u{2082}O\u{2086} + 6O\u{2082}", tags: ["science", "biology"]),
            Flashcard(question: "Who wrote Romeo and Juliet?", answer: "William Shakespeare", notes: "Written around 1594\u{2013}1596.", tags: ["literature", "history"]),
            Flashcard(question: "What is the powerhouse of the cell?", answer: "Mitochondria", notes: "Generates most of the cell's ATP supply.", tags: ["science", "biology"]),
            Flashcard(question: "What year did World War II end?", answer: "1945", notes: "Germany in May, Japan in August after Hiroshima and Nagasaki.", tags: ["history"]),
            Flashcard(question: "Chemical symbol for gold?", answer: "Au", notes: "From Latin 'aurum'. Atomic number 79.", tags: ["science", "chemistry"]),
            Flashcard(question: "Largest ocean on Earth?", answer: "Pacific Ocean", notes: "165.25 million km\u{00B2} \u{2014} more than all land combined.", tags: ["geography"]),
            Flashcard(question: "What does CPU stand for?", answer: "Central Processing Unit", notes: "The 'brain' of the computer.", tags: ["technology"]),
            Flashcard(question: "Pythagorean theorem?", answer: "a\u{00B2} + b\u{00B2} = c\u{00B2}", notes: "For right triangles only.", tags: ["math"]),
            Flashcard(question: "Which planet is the Red Planet?", answer: "Mars", notes: "Red from iron oxide. Moons: Phobos and Deimos.", tags: ["science", "space"]),
        ]
        decks.append(Deck(name: "Study Starter Pack", cards: cards))
    }

    // MARK: Local Persistence
    func save() {
        if let data = try? JSONEncoder().encode(decks) {
            UserDefaults.standard.set(data, forKey: decksKey)
        }
        if settings.iCloudSync { saveToICloud() }
    }

    func loadDecks() {
        // Try iCloud first if enabled
        if settings.iCloudSync, let iCloudDecks = loadFromICloud() {
            decks = iCloudDecks
            return
        }
        if let data = UserDefaults.standard.data(forKey: decksKey),
           let decoded = try? JSONDecoder().decode([Deck].self, from: data) {
            decks = decoded
        }
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "app_settings")
        }
        if settings.iCloudSync {
            NSUbiquitousKeyValueStore.default.set(try? JSONEncoder().encode(settings), forKey: "app_settings_cloud")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "app_settings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }

    // MARK: iCloud Sync
    func saveToICloud() {
        guard let data = try? JSONEncoder().encode(decks) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: "decks_cloud_v3")
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func loadFromICloud() -> [Deck]? {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: "decks_cloud_v3"),
              let decoded = try? JSONDecoder().decode([Deck].self, from: data) else { return nil }
        return decoded
    }

    func setupICloudObserver() {
        iCloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, self.settings.iCloudSync else { return }
            // Merge remote changes
            if let data = NSUbiquitousKeyValueStore.default.data(forKey: "decks_cloud_v3"),
               let remoteDecks = try? JSONDecoder().decode([Deck].self, from: data) {
                // Simple last-write-wins: use remote if it has more total cards or decks
                let localCount = self.decks.reduce(0) { $0 + $1.cards.count }
                let remoteCount = remoteDecks.reduce(0) { $0 + $1.cards.count }
                if remoteDecks.count > self.decks.count || remoteCount > localCount {
                    self.decks = remoteDecks
                }
            }
        }
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func enableICloudSync() {
        settings.iCloudSync = true
        saveToICloud()
    }

    func disableICloudSync() {
        settings.iCloudSync = false
    }

    // MARK: Deck ops
    func addDeck(_ name: String) { decks.append(Deck(name: name)) }
    func deleteDeck(id: UUID) { decks.removeAll { $0.id == id } }
    func renameDeck(id: UUID, to name: String) {
        if let i = idx(id) { decks[i].name = name }
    }

    // MARK: Card ops
    func addCard(to did: UUID, card: Flashcard) {
        if let i = idx(did) { decks[i].cards.append(card) }
    }
    func updateCard(in did: UUID, card: Flashcard) {
        if let di = idx(did), let ci = decks[di].cards.firstIndex(where: { $0.id == card.id }) {
            decks[di].cards[ci] = card
        }
    }
    func deleteCard(in did: UUID, cardID: UUID) {
        if let di = idx(did) { decks[di].cards.removeAll { $0.id == cardID } }
    }
    func shuffleDeck(_ did: UUID) {
        if let i = idx(did) { decks[i].cards.shuffle() }
    }

    // MARK: Import
    func importCards(to did: UUID, cards: [Flashcard]) {
        if let i = idx(did) {
            decks[i].cards.append(contentsOf: cards)
        }
    }

    func importDeck(_ deck: Deck) {
        decks.append(deck)
    }

    var allTags: [String] {
        Array(Set(decks.flatMap { $0.cards.flatMap { $0.tags } })).sorted()
    }

    private func idx(_ did: UUID) -> Int? { decks.firstIndex(where: { $0.id == did }) }
}


// ============================================================
// MARK: - Helpers
// ============================================================

struct CuteTheme {
    static let pink = Color(red: 0.96, green: 0.72, blue: 0.76)
    static let softPink = Color(red: 0.99, green: 0.93, blue: 0.94)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.93)
    static let sky = Color(red: 0.86, green: 0.90, blue: 0.98)
    static let accent = Color(red: 0.78, green: 0.42, blue: 0.56)
    static let cardBG = Color(red: 1.0, green: 0.995, blue: 0.99)
    static let subtle = Color(red: 0.50, green: 0.44, blue: 0.48)
}

#if canImport(UIKit)
func compressImage(_ data: Data, maxWidth: CGFloat = 600) -> Data? {
    guard let img = UIImage(data: data) else { return nil }
    let scale = min(1.0, maxWidth / img.size.width)
    let sz = CGSize(width: img.size.width * scale, height: img.size.height * scale)
    UIGraphicsBeginImageContextWithOptions(sz, false, 1.0)
    img.draw(in: CGRect(origin: .zero, size: sz))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resized?.jpegData(compressionQuality: 0.6)
}
#elseif canImport(AppKit)
func compressImage(_ data: Data, maxWidth: CGFloat = 600) -> Data? {
    guard let img = NSImage(data: data) else { return nil }
    let rep = img.representations.first
    let w = CGFloat(rep?.pixelsWide ?? Int(img.size.width))
    let h = CGFloat(rep?.pixelsHigh ?? Int(img.size.height))
    let scale = min(1.0, maxWidth / w)
    let newSize = NSSize(width: w * scale, height: h * scale)
    let newImg = NSImage(size: newSize)
    newImg.lockFocus()
    img.draw(in: NSRect(origin: .zero, size: newSize))
    newImg.unlockFocus()
    guard let tiffData = newImg.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.6]) else { return nil }
    return jpeg
}
#endif

func hapticLight() {
    #if canImport(UIKit)
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    #endif
}

func hapticMedium() {
    #if canImport(UIKit)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    #endif
}

func hapticSoft() {
    #if canImport(UIKit)
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    #endif
}

// ============================================================
// MARK: - Import Helpers
// ============================================================

func parseCSVImport(_ text: String) -> [Flashcard] {
    var cards: [Flashcard] = []
    let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    guard lines.count > 1 else { return cards }

    // Skip header row
    for line in lines.dropFirst() {
        let fields = parseCSVLine(line)
        guard fields.count >= 2 else { continue }
        let q = fields[0].trimmingCharacters(in: .whitespaces)
        let a = fields[1].trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty && !a.isEmpty else { continue }
        let notes = fields.count > 2 ? fields[2].trimmingCharacters(in: .whitespaces) : ""
        let tags = fields.count > 3 ? fields[3].split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces).lowercased() } : []
        cards.append(Flashcard(question: q, answer: a, notes: notes, tags: tags))
    }
    return cards
}

func parseCSVLine(_ line: String) -> [String] {
    var fields: [String] = []
    var current = ""
    var inQuotes = false
    var chars = line.makeIterator()
    while let ch = chars.next() {
        if inQuotes {
            if ch == "\"" {
                // Check for escaped quote
                if let next = chars.next() {
                    if next == "\"" { current.append("\"") }
                    else { inQuotes = false; if next == "," { fields.append(current); current = "" } else { current.append(next) } }
                } else { inQuotes = false }
            } else { current.append(ch) }
        } else {
            if ch == "\"" { inQuotes = true }
            else if ch == "," { fields.append(current); current = "" }
            else { current.append(ch) }
        }
    }
    fields.append(current)
    return fields
}

func parseJSONImport(_ data: Data) -> [Flashcard]? {
    // Try decoding as array of Flashcards
    if let cards = try? JSONDecoder().decode([Flashcard].self, from: data) {
        return cards
    }
    // Try decoding as a Deck
    if let deck = try? JSONDecoder().decode(Deck.self, from: data) {
        return deck.cards
    }
    // Try decoding as array of simple dicts
    if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
        var cards: [Flashcard] = []
        for dict in arr {
            guard let q = dict["question"] as? String, let a = dict["answer"] as? String else { continue }
            let notes = dict["notes"] as? String ?? ""
            let tags = dict["tags"] as? [String] ?? []
            cards.append(Flashcard(question: q, answer: a, notes: notes, tags: tags))
        }
        return cards.isEmpty ? nil : cards
    }
    return nil
}

/// Parses plain text in Q:/A: format, or tab-separated format.
///
/// Supported formats:
/// ```
/// Q: What is the capital of France?
/// A: Paris
/// N: Optional notes
/// T: tag1, tag2
///
/// Q: Next question
/// A: Next answer
/// ```
/// Or tab-separated: `question[TAB]answer[TAB]notes[TAB]tags`
func parsePlainTextImport(_ text: String) -> [Flashcard] {
    let lines = text.components(separatedBy: .newlines)

    // Detect format: if first non-empty line starts with Q: use Q/A format
    let firstNonEmpty = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
    let trimmed = firstNonEmpty.trimmingCharacters(in: .whitespaces)

    if trimmed.hasPrefix("Q:") || trimmed.hasPrefix("q:") {
        return parseQAFormat(lines)
    } else if trimmed.contains("\t") {
        return parseTabFormat(lines)
    } else {
        // Try Q/A format anyway (maybe blank lines before Q:)
        let qaCards = parseQAFormat(lines)
        if !qaCards.isEmpty { return qaCards }
        // Fallback: try tab format
        return parseTabFormat(lines)
    }
}

private func parseQAFormat(_ lines: [String]) -> [Flashcard] {
    var cards: [Flashcard] = []
    var currentQ = ""
    var currentA = ""
    var currentN = ""
    var currentT: [String] = []

    func flushCard() {
        let q = currentQ.trimmingCharacters(in: .whitespaces)
        let a = currentA.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty && !a.isEmpty {
            cards.append(Flashcard(question: q, answer: a, notes: currentN.trimmingCharacters(in: .whitespaces), tags: currentT))
        }
        currentQ = ""; currentA = ""; currentN = ""; currentT = []
    }

    for line in lines {
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.isEmpty {
            // Blank line: flush if we have a card
            if !currentQ.isEmpty { flushCard() }
            continue
        }

        let lower = t.lowercased()
        if lower.hasPrefix("q:") {
            if !currentQ.isEmpty { flushCard() }
            currentQ = String(t.dropFirst(2))
        } else if lower.hasPrefix("a:") {
            currentA = String(t.dropFirst(2))
        } else if lower.hasPrefix("n:") {
            currentN = String(t.dropFirst(2))
        } else if lower.hasPrefix("t:") {
            let tagStr = String(t.dropFirst(2))
            currentT = tagStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
        } else {
            // Continuation of previous field
            if !currentA.isEmpty { currentA += " " + t }
            else if !currentQ.isEmpty { currentQ += " " + t }
        }
    }
    flushCard()
    return cards
}

private func parseTabFormat(_ lines: [String]) -> [Flashcard] {
    var cards: [Flashcard] = []
    for line in lines {
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { continue }
        let fields = t.components(separatedBy: "\t")
        guard fields.count >= 2 else { continue }
        let q = fields[0].trimmingCharacters(in: .whitespaces)
        let a = fields[1].trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty && !a.isEmpty else { continue }
        let notes = fields.count > 2 ? fields[2].trimmingCharacters(in: .whitespaces) : ""
        let tags: [String] = fields.count > 3 ? fields[3].split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces).lowercased() } : []
        cards.append(Flashcard(question: q, answer: a, notes: notes, tags: tags))
    }
    return cards
}


// ============================================================
// MARK: - Rich Text Helpers
// ============================================================

func rtfToAttributed(_ data: Data?) -> NSAttributedString? {
    guard let data = data else { return nil }
    return try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
}

func attributedToRTF(_ attr: NSAttributedString) -> Data? {
    guard attr.length > 0 else { return nil }
    return try? attr.data(from: NSRange(location: 0, length: attr.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
}

func attributedToPlain(_ attr: NSAttributedString) -> String {
    attr.string.trimmingCharacters(in: .whitespacesAndNewlines)
}

// ============================================================
// MARK: - Rich Text Editor
// ============================================================

#if canImport(UIKit)
struct RichTextEditorView: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var minHeight: CGFloat = 100

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = UIFont.systemFont(ofSize: 17)
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        tv.backgroundColor = .clear
        tv.isScrollEnabled = true
        tv.inputAccessoryView = context.coordinator.makeToolbar(tv)
        if attributedText.length > 0 {
            tv.attributedText = attributedText
        }
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if context.coordinator.isUpdating { return }
        if uiView.attributedText != attributedText {
            let sel = uiView.selectedRange
            uiView.attributedText = attributedText
            if sel.location <= attributedText.length {
                uiView.selectedRange = sel
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditorView
        var isUpdating = false

        init(_ p: RichTextEditorView) { parent = p }

        func textViewDidChange(_ textView: UITextView) {
            isUpdating = true
            parent.attributedText = textView.attributedText ?? NSAttributedString()
            isUpdating = false
        }

        func makeToolbar(_ tv: UITextView) -> UIToolbar {
            let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            bar.barTintColor = UIColor.systemBackground

            let bold = UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: self, action: #selector(toggleBold(_:)))
            let italic = UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: self, action: #selector(toggleItalic(_:)))
            let underline = UIBarButtonItem(image: UIImage(systemName: "underline"), style: .plain, target: self, action: #selector(toggleUnderline(_:)))
            let sizeUp = UIBarButtonItem(image: UIImage(systemName: "textformat.size.larger"), style: .plain, target: self, action: #selector(increaseFontSize(_:)))
            let sizeDown = UIBarButtonItem(image: UIImage(systemName: "textformat.size.smaller"), style: .plain, target: self, action: #selector(decreaseFontSize(_:)))

            let fontMenu = UIBarButtonItem(title: "Font", menu: makeFontMenu(tv))
            fontMenu.image = UIImage(systemName: "textformat")

            let flex = UIBarButtonItem.flexibleSpace()
            let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard(_:)))

            bar.items = [bold, italic, underline, flex, sizeDown, sizeUp, flex, fontMenu, flex, done]
            bar.tag = 999
            objc_setAssociatedObject(self, &Coordinator.tvKey, tv, .OBJC_ASSOCIATION_ASSIGN)
            return bar
        }

        private static var tvKey: UInt8 = 0
        private var textView: UITextView? {
            objc_getAssociatedObject(self, &Coordinator.tvKey) as? UITextView
        }

        func makeFontMenu(_ tv: UITextView) -> UIMenu {
            let fonts: [(String, String)] = [
                ("System", ".SFUI-Regular"),
                ("Rounded", ".SFUIRounded-Regular"),
                ("Serif", "Georgia"),
                ("Mono", "Menlo-Regular"),
                ("Marker", "MarkerFelt-Wide"),
                ("Avenir", "Avenir-Medium"),
                ("Palatino", "Palatino-Roman"),
            ]
            let actions = fonts.map { (name, fontName) in
                UIAction(title: name) { [weak self] _ in
                    self?.applyFont(fontName, to: tv)
                }
            }
            return UIMenu(title: "Font", children: actions)
        }

        func applyFont(_ fontName: String, to tv: UITextView) {
            let range = tv.selectedRange
            guard range.length > 0 else {
                let size = currentFontSize(tv)
                let font: UIFont
                if fontName.hasPrefix(".SF") {
                    font = fontName.contains("Rounded") ?
                        UIFont.systemFont(ofSize: size, weight: .regular).withDesign(.rounded) ?? UIFont.systemFont(ofSize: size) :
                        UIFont.systemFont(ofSize: size)
                } else {
                    font = UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size)
                }
                tv.typingAttributes[.font] = font
                return
            }
            let ms = NSMutableAttributedString(attributedString: tv.attributedText)
            ms.enumerateAttribute(.font, in: range) { val, r, _ in
                let existing = (val as? UIFont) ?? UIFont.systemFont(ofSize: 17)
                let size = existing.pointSize
                let traits = existing.fontDescriptor.symbolicTraits
                let newFont: UIFont
                if fontName.hasPrefix(".SF") {
                    var base = fontName.contains("Rounded") ?
                        UIFont.systemFont(ofSize: size).withDesign(.rounded) ?? UIFont.systemFont(ofSize: size) :
                        UIFont.systemFont(ofSize: size)
                    if let desc = base.fontDescriptor.withSymbolicTraits(traits) {
                        base = UIFont(descriptor: desc, size: size)
                    }
                    newFont = base
                } else {
                    var base = UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size)
                    if let desc = base.fontDescriptor.withSymbolicTraits(traits) {
                        base = UIFont(descriptor: desc, size: size)
                    }
                    newFont = base
                }
                ms.addAttribute(.font, value: newFont, range: r)
            }
            tv.attributedText = ms
            tv.selectedRange = range
            textViewDidChange(tv)
        }

        @objc func toggleBold(_ sender: Any) { toggleTrait(.traitBold) }
        @objc func toggleItalic(_ sender: Any) { toggleTrait(.traitItalic) }

        @objc func toggleUnderline(_ sender: Any) {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            if range.length == 0 {
                let current = tv.typingAttributes[.underlineStyle] as? Int ?? 0
                tv.typingAttributes[.underlineStyle] = current == 0 ? NSUnderlineStyle.single.rawValue : 0
                return
            }
            let ms = NSMutableAttributedString(attributedString: tv.attributedText)
            var hasUnderline = false
            ms.enumerateAttribute(.underlineStyle, in: range) { val, _, _ in
                if let v = val as? Int, v != 0 { hasUnderline = true }
            }
            ms.addAttribute(.underlineStyle, value: hasUnderline ? 0 : NSUnderlineStyle.single.rawValue, range: range)
            tv.attributedText = ms; tv.selectedRange = range; textViewDidChange(tv)
        }

        @objc func increaseFontSize(_ sender: Any) { changeFontSize(by: 2) }
        @objc func decreaseFontSize(_ sender: Any) { changeFontSize(by: -2) }
        @objc func dismissKeyboard(_ sender: Any) { textView?.resignFirstResponder() }

        func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            if range.length == 0 {
                let font = tv.typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 17)
                let has = font.fontDescriptor.symbolicTraits.contains(trait)
                let newTraits = has ? font.fontDescriptor.symbolicTraits.subtracting(trait) : font.fontDescriptor.symbolicTraits.union(trait)
                if let desc = font.fontDescriptor.withSymbolicTraits(newTraits) {
                    tv.typingAttributes[.font] = UIFont(descriptor: desc, size: font.pointSize)
                }
                return
            }
            let ms = NSMutableAttributedString(attributedString: tv.attributedText)
            ms.enumerateAttribute(.font, in: range) { val, r, _ in
                let font = (val as? UIFont) ?? UIFont.systemFont(ofSize: 17)
                let has = font.fontDescriptor.symbolicTraits.contains(trait)
                let newTraits = has ? font.fontDescriptor.symbolicTraits.subtracting(trait) : font.fontDescriptor.symbolicTraits.union(trait)
                if let desc = font.fontDescriptor.withSymbolicTraits(newTraits) {
                    ms.addAttribute(.font, value: UIFont(descriptor: desc, size: font.pointSize), range: r)
                }
            }
            tv.attributedText = ms; tv.selectedRange = range; textViewDidChange(tv)
        }

        func changeFontSize(by delta: CGFloat) {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            if range.length == 0 {
                let font = tv.typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 17)
                let newSize = max(10, min(48, font.pointSize + delta))
                tv.typingAttributes[.font] = font.withSize(newSize)
                return
            }
            let ms = NSMutableAttributedString(attributedString: tv.attributedText)
            ms.enumerateAttribute(.font, in: range) { val, r, _ in
                let font = (val as? UIFont) ?? UIFont.systemFont(ofSize: 17)
                let newSize = max(10, min(48, font.pointSize + delta))
                ms.addAttribute(.font, value: font.withSize(newSize), range: r)
            }
            tv.attributedText = ms; tv.selectedRange = range; textViewDidChange(tv)
        }

        func currentFontSize(_ tv: UITextView) -> CGFloat {
            (tv.typingAttributes[.font] as? UIFont)?.pointSize ?? 17
        }
    }
}

extension UIFont {
    func withDesign(_ design: UIFontDescriptor.SystemDesign) -> UIFont? {
        guard let desc = fontDescriptor.withDesign(design) else { return nil }
        return UIFont(descriptor: desc, size: pointSize)
    }
}
#endif

// macOS: simplified plain-text editor fallback
#if canImport(AppKit)
struct RichTextEditorView: View {
    @Binding var attributedText: NSAttributedString
    var minHeight: CGFloat = 100
    @State private var plainText: String = ""

    var body: some View {
        TextEditor(text: $plainText)
            .frame(minHeight: minHeight)
            .onAppear { plainText = attributedText.string }
            .onChange(of: plainText) { newVal in
                attributedText = NSAttributedString(string: newVal)
            }
    }
}
#endif

// ============================================================
// MARK: - Rich Text Display
// ============================================================

#if canImport(UIKit)
struct RichTextLabel: UIViewRepresentable {
    let attributedText: NSAttributedString
    var textColor: UIColor = .label
    var textAlignment: NSTextAlignment = .center

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        let ms = NSMutableAttributedString(attributedString: attributedText)
        let full = NSRange(location: 0, length: ms.length)
        let ps = NSMutableParagraphStyle()
        ps.alignment = textAlignment
        ms.addAttribute(.paragraphStyle, value: ps, range: full)
        ms.enumerateAttribute(.foregroundColor, in: full) { val, r, _ in
            if val == nil { ms.addAttribute(.foregroundColor, value: textColor, range: r) }
        }
        uiView.attributedText = ms
        uiView.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 120
    }
}
#endif

#if canImport(AppKit)
struct RichTextLabel: View {
    let attributedText: NSAttributedString
    var textColor: NSColor = .labelColor
    var textAlignment: NSTextAlignment = .center

    var body: some View {
        Text(attributedText.string)
            .multilineTextAlignment(.center)
    }
}
#endif


// ============================================================
// MARK: - App Entry
// ============================================================

@main
struct FlashcardApp: App {
    @StateObject private var store = DataStore()
    var body: some Scene {
        WindowGroup {
            AdaptiveHomeView()
                .environmentObject(store)
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 650)
        #endif
    }
}

// ============================================================
// MARK: - Background
// ============================================================

struct AppBG: View {
    @EnvironmentObject var store: DataStore
    var body: some View {
        LinearGradient(
            colors: BGTheme.colors(for: store.settings.backgroundTheme),
            startPoint: .topLeading, endPoint: .bottomTrailing
        ).ignoresSafeArea()
    }
}

// ============================================================
// MARK: - Adaptive Layout (iPhone vs iPad/Mac)
// ============================================================

struct AdaptiveHomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .regular {
            iPadHomeView()
        } else {
            HomeView()
        }
    }
}

// ============================================================
// MARK: - iPad / Mac Sidebar Layout
// ============================================================

struct iPadHomeView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedDeck: UUID? = nil
    @State private var showNewDeck = false
    @State private var newDeckName = ""
    @State private var showSearch = false
    @State private var showSettings = false
    @State private var showRenameTitle = false
    @State private var newTitle = ""
    @State private var showImport = false

    var body: some View {
        NavigationSplitView {
            ZStack {
                AppBG()
                sidebarContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .principal) {
                    Button { newTitle = store.appTitle; showRenameTitle = true } label: {
                        Text(store.appTitle)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                }
                #endif
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { showSearch = true } label: { Image(systemName: "magnifyingglass") }
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                    Menu {
                        Button { showNewDeck = true } label: { Label("New Deck", systemImage: "plus") }
                        Button { showImport = true } label: { Label("Import", systemImage: "square.and.arrow.down") }
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }.tint(CuteTheme.accent)
                }
            }
            .sheet(isPresented: $showSearch) { SearchView(navPath: .constant(NavigationPath())) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showImport) { ImportView() }
            .alert("New Deck", isPresented: $showNewDeck) {
                TextField("Deck name", text: $newDeckName)
                Button("Create") {
                    let n = newDeckName.trimmingCharacters(in: .whitespaces)
                    if !n.isEmpty { store.addDeck(n) }
                    newDeckName = ""
                }
                Button("Cancel", role: .cancel) { newDeckName = "" }
            }
            .alert("Rename App Title", isPresented: $showRenameTitle) {
                TextField("Title", text: $newTitle)
                Button("Save") {
                    let t = newTitle.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty { store.appTitle = t }
                    newTitle = ""
                }
                Button("Cancel", role: .cancel) { newTitle = "" }
            }
        } detail: {
            if let deckID = selectedDeck, store.decks.contains(where: { $0.id == deckID }) {
                DeckView(deckID: deckID)
            } else {
                ZStack {
                    AppBG()
                    VStack(spacing: 16) {
                        Text("\u{1F4DA}").font(.system(size: 52))
                        Text("Select a deck").font(.title3.weight(.medium)).foregroundStyle(ThemeColors(settings: store.settings).emptyText)
                    }
                }
            }
        }
        .onChange(of: store.pendingDeckNav) { did in
            if let did = did {
                selectedDeck = did
                store.pendingDeckNav = nil
            }
        }
    }

    var sidebarContent: some View {
        Group {
            if store.decks.isEmpty {
                VStack(spacing: 20) {
                    HStack(spacing: -8) {
                        Text("\u{1F42E}").font(.system(size: 40)).rotationEffect(.degrees(-10))
                        Text("\u{1F430}").font(.system(size: 48))
                        Text("\u{1F43C}").font(.system(size: 40)).rotationEffect(.degrees(10))
                    }
                    Text("No decks yet!").font(.title3.weight(.semibold)).foregroundStyle(CuteTheme.subtle)
                    Button { showNewDeck = true } label: {
                        HStack(spacing: 6) { Text("\u{2728}"); Text("Create First Deck").font(.subheadline.weight(.semibold)) }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28).padding(.vertical, 13)
                            .background(LinearGradient(colors: [CuteTheme.pink, CuteTheme.accent], startPoint: .leading, endPoint: .trailing), in: Capsule())
                            .shadow(color: CuteTheme.accent.opacity(0.35), radius: 10, y: 5)
                    }
                }
            } else {
                List(selection: $selectedDeck) {
                    ForEach(store.decks) { deck in
                        HStack(spacing: 14) {
                            Text("\u{1F4DA}").font(.title2)
                                .frame(width: 46, height: 46)
                                .background(CuteTheme.pink.opacity(0.25), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(deck.name).font(.subheadline.weight(.semibold))
                                Text("\(deck.cards.count) card\(deck.cards.count == 1 ? "" : "s")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .tag(deck.id)
                        .contextMenu {
                            Button(role: .destructive) { store.deleteDeck(id: deck.id) } label: {
                                Label("Delete Deck", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
}


// ============================================================
// MARK: - Home View (iPhone Stack Layout)
// ============================================================

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @State private var showNewDeck = false
    @State private var newDeckName = ""
    @State private var showSearch = false
    @State private var showSettings = false
    @State private var showRenameTitle = false
    @State private var newTitle = ""
    @State private var navPath = NavigationPath()
    @State private var showImport = false

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                AppBG()
                if store.decks.isEmpty {
                    emptyView
                } else {
                    deckList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .principal) {
                    Button { newTitle = store.appTitle; showRenameTitle = true } label: {
                        Text(store.appTitle)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                }
                #endif
            }
            .toolbar { homeToolbar }
            .navigationDestination(for: UUID.self) { deckID in
                DeckView(deckID: deckID)
            }
            .sheet(isPresented: $showSearch) { SearchView(navPath: $navPath) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showImport) { ImportView() }
            .alert("New Deck", isPresented: $showNewDeck) {
                TextField("Deck name", text: $newDeckName)
                Button("Create") {
                    let n = newDeckName.trimmingCharacters(in: .whitespaces)
                    if !n.isEmpty { store.addDeck(n) }
                    newDeckName = ""
                }
                Button("Cancel", role: .cancel) { newDeckName = "" }
            }
            .alert("Rename App Title", isPresented: $showRenameTitle) {
                TextField("Title", text: $newTitle)
                Button("Save") {
                    let t = newTitle.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty { store.appTitle = t }
                    newTitle = ""
                }
                Button("Cancel", role: .cancel) { newTitle = "" }
            }
            .onChange(of: store.pendingDeckNav) { did in
                if let did = did {
                    navPath = NavigationPath()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navPath.append(did)
                    }
                    store.pendingDeckNav = nil
                }
            }
        }
    }

    var emptyView: some View {
        VStack(spacing: 20) {
            HStack(spacing: -8) {
                Text("\u{1F42E}").font(.system(size: 40)).rotationEffect(.degrees(-10))
                Text("\u{1F430}").font(.system(size: 48))
                Text("\u{1F43C}").font(.system(size: 40)).rotationEffect(.degrees(10))
            }
            Text("No decks yet!").font(.title3.weight(.semibold)).foregroundStyle(CuteTheme.subtle)
            Button { showNewDeck = true } label: {
                HStack(spacing: 6) { Text("\u{2728}"); Text("Create First Deck").font(.subheadline.weight(.semibold)) }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28).padding(.vertical, 13)
                    .background(LinearGradient(colors: [CuteTheme.pink, CuteTheme.accent], startPoint: .leading, endPoint: .trailing), in: Capsule())
                    .shadow(color: CuteTheme.accent.opacity(0.35), radius: 10, y: 5)
            }
        }
    }

    var deckList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(store.decks) { deck in
                    NavigationLink(value: deck.id) {
                        deckRow(deck)
                    }
                    .contextMenu {
                        Button(role: .destructive) { store.deleteDeck(id: deck.id) } label: {
                            Label("Delete Deck", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal).padding(.top, 10)
        }
    }

    func deckRow(_ deck: Deck) -> some View {
        let tc = ThemeColors(settings: store.settings)
        return HStack(spacing: 14) {
            Text("\u{1F4DA}").font(.title2)
                .frame(width: 46, height: 46)
                .background(CuteTheme.pink.opacity(0.25), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(deck.name).font(.subheadline.weight(.semibold)).foregroundStyle(tc.primaryText)
                Text("\(deck.cards.count) card\(deck.cards.count == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(tc.cardCount)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2.bold()).foregroundStyle(tc.chevron)
        }
        .padding(14)
        .background(tc.deckRowBG, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: tc.deckRowShadow, radius: 8, y: 4)
    }

    @ToolbarContentBuilder
    var homeToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button { showSearch = true } label: { Image(systemName: "magnifyingglass") }
            Button { showSettings = true } label: { Image(systemName: "gearshape") }
            Menu {
                Button { showNewDeck = true } label: { Label("New Deck", systemImage: "plus") }
                Button { showImport = true } label: { Label("Import", systemImage: "square.and.arrow.down") }
            } label: {
                Image(systemName: "plus.circle.fill").font(.title3)
            }.tint(CuteTheme.accent)
        }
    }
}


// ============================================================
// MARK: - Deck View
// ============================================================

struct DeckView: View {
    @EnvironmentObject var store: DataStore
    let deckID: UUID
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var showNotes = false
    @State private var showAddCard = false
    @State private var showEditCard = false
    @State private var showDeleteAlert = false
    @State private var showCardList = false
    @State private var showRenameDeck = false
    @State private var showExport = false
    @State private var showSearch = false
    @State private var showSettings = false
    @State private var showTagFilter = false
    @State private var showImport = false
    @State private var newDeckName = ""
    @State private var dragOffset: CGFloat = 0
    @State private var filterTags: Set<String> = []

    var deck: Deck? { store.decks.first { $0.id == deckID } }
    var filteredCards: [Flashcard] {
        guard let deck = deck else { return [] }
        if filterTags.isEmpty { return deck.cards }
        return deck.cards.filter { !filterTags.isDisjoint(with: $0.tags) }
    }
    var deckTags: [String] {
        Array(Set(deck?.cards.flatMap { $0.tags } ?? [])).sorted()
    }
    var safeIndex: Int {
        guard !filteredCards.isEmpty else { return 0 }
        return min(currentIndex, filteredCards.count - 1)
    }

    var body: some View {
        ZStack {
            AppBG()
            if filteredCards.isEmpty {
                deckEmptyView
            } else {
                cardBrowser
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { deckToolbar }
        .sheet(isPresented: $showAddCard) { addSheet }
        .sheet(isPresented: $showEditCard) { editSheet }
        .sheet(isPresented: $showSearch) { SearchView(navPath: .constant(NavigationPath())) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showImport) { ImportView(targetDeckID: deckID) }
        .sheet(isPresented: $showCardList) {
            CardListView(deckID: deckID, currentIndex: $currentIndex, isFlipped: $isFlipped, showNotes: $showNotes)
        }
        .sheet(isPresented: $showExport) { ExportView(deckID: deckID) }
        .sheet(isPresented: $showTagFilter) { tagFilterSheet }
        .alert("Delete card? \u{1F97A}", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteCurrentCard() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Rename Deck", isPresented: $showRenameDeck) {
            TextField("Name", text: $newDeckName)
            Button("Save") {
                let n = newDeckName.trimmingCharacters(in: .whitespaces)
                if !n.isEmpty { store.renameDeck(id: deckID, to: n) }
                newDeckName = ""
            }
            Button("Cancel", role: .cancel) { newDeckName = "" }
        }
        .onChange(of: filterTags) { _ in currentIndex = 0; isFlipped = false; showNotes = false }
        .onAppear { handlePendingJump() }
    }

    func handlePendingJump() {
        guard let cardID = store.pendingCardID,
              let idx = filteredCards.firstIndex(where: { $0.id == cardID }) else { return }
        currentIndex = idx
        isFlipped = false
        showNotes = false
        store.pendingCardID = nil
    }

    // MARK: Empty
    var deckEmptyView: some View {
        let tc = ThemeColors(settings: store.settings)
        return VStack(spacing: 16) {
            Button { newDeckName = deck?.name ?? ""; showRenameDeck = true } label: {
                Text(deck?.name ?? "Deck")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tc.accentText)
                    .tracking(0.3)
            }
            .padding(.top, 12)
            Spacer()
            if !filterTags.isEmpty {
                Text("No cards match filters").font(.subheadline.weight(.medium)).foregroundStyle(tc.emptyText)
                Button("Clear Filters") { filterTags.removeAll() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(CuteTheme.accent, in: Capsule())
            } else {
                Text("\u{1F423}").font(.system(size: 52))
                Text("No cards yet").font(.subheadline.weight(.medium)).foregroundStyle(tc.emptyText)
                HStack(spacing: 12) {
                    Button("Add Card") { showAddCard = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(CuteTheme.accent, in: Capsule())
                    Button("Import") { showImport = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CuteTheme.accent)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(CuteTheme.accent.opacity(0.15), in: Capsule())
                }
            }
            Spacer()
        }
    }

    // MARK: Card Browser
    var cardBrowser: some View {
        let tc = ThemeColors(settings: store.settings)
        return VStack(spacing: 0) {
            Button { newDeckName = deck?.name ?? ""; showRenameDeck = true } label: {
                Text(deck?.name ?? "Deck")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tc.accentText)
                    .tracking(0.3)
            }
            .padding(.top, 12).padding(.bottom, 6)

            if !filterTags.isEmpty {
                activeFilterBar
            }

            Spacer(minLength: 4)

            FlashcardView(
                card: filteredCards[safeIndex],
                cardIndex: safeIndex,
                isFlipped: $isFlipped,
                showNotes: $showNotes,
                settings: store.settings
            )
            .offset(x: dragOffset)
            .gesture(swipeGesture)

            Spacer(minLength: 4)

            if filteredCards.count > 1 {
                DotIndicators(total: filteredCards.count, current: safeIndex)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            if currentIndex >= filteredCards.count {
                currentIndex = max(filteredCards.count - 1, 0)
            }
        }
    }

    var activeFilterBar: some View {
        let tc = ThemeColors(settings: store.settings)
        return HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(tc.filterBarText).font(.caption)
            Text("\(filterTags.count) tag\(filterTags.count == 1 ? "" : "s") active")
                .font(.caption2.weight(.medium)).foregroundStyle(tc.filterBarText)
            Spacer()
            Button("Clear") { filterTags.removeAll() }
                .font(.caption2.weight(.medium)).foregroundStyle(.red.opacity(0.6))
        }
        .padding(.horizontal).padding(.vertical, 6)
    }

    // MARK: Tag Filter Sheet
    var tagFilterSheet: some View {
        NavigationStack {
            List {
                if deckTags.isEmpty {
                    Text("No tags in this deck yet").foregroundStyle(.secondary)
                } else {
                    ForEach(deckTags, id: \.self) { tag in
                        Button {
                            if filterTags.contains(tag) { filterTags.remove(tag) }
                            else { filterTags.insert(tag) }
                        } label: {
                            HStack {
                                Text(tag)
                                Spacer()
                                if filterTags.contains(tag) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(CuteTheme.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Filter by Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showTagFilter = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !filterTags.isEmpty {
                        Button("Clear All") { filterTags.removeAll() }
                    }
                }
            }
        }
    }

    // MARK: Toolbar
    func toolbarAction(_ id: String) {
        switch id {
        case "search": showSearch = true
        case "edit": showEditCard = true
        case "shuffle":
            store.shuffleDeck(deckID)
            currentIndex = 0; isFlipped = false; showNotes = false
            hapticMedium()
        case "filter": showTagFilter = true
        case "list": showCardList = true
        case "add": showAddCard = true
        case "export": showExport = true
        case "settings": showSettings = true
        case "delete": showDeleteAlert = true
        default: break
        }
    }

    func iconFor(_ id: String) -> String {
        AppSettings.allActions.first { $0.id == id }?.icon ?? "questionmark"
    }

    var pinnedActions: [String] { store.settings.toolbarActions }
    var overflowActions: [String] {
        AppSettings.allActions.map(\.id).filter { !pinnedActions.contains($0) }
    }

    @ToolbarContentBuilder
    var deckToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: 14) {
                ForEach(pinnedActions, id: \.self) { id in
                    Button { toolbarAction(id) } label: {
                        Image(systemName: iconFor(id))
                            .font(id == "add" ? .title3 : .body)
                            .foregroundStyle(id == "add" ? CuteTheme.accent : id == "delete" ? .red.opacity(0.7) : .primary)
                    }
                }
                Menu {
                    ForEach(overflowActions, id: \.self) { id in
                        if let action = AppSettings.allActions.first(where: { $0.id == id }) {
                            if id == "delete" {
                                Button(role: .destructive) { toolbarAction(id) } label: {
                                    Label(action.label, systemImage: action.icon)
                                }
                            } else {
                                Button { toolbarAction(id) } label: {
                                    Label(action.label, systemImage: action.icon)
                                }
                            }
                        }
                    }
                    Divider()
                    Button { showImport = true } label: { Label("Import", systemImage: "square.and.arrow.down") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    // MARK: Sheets
    var addSheet: some View {
        CardFormView(mode: .add, deckTags: deckTags) { card in
            store.addCard(to: deckID, card: card)
            currentIndex = max(filteredCards.count - 1, 0)
            isFlipped = false; showNotes = false
        }
    }
    @ViewBuilder var editSheet: some View {
        if filteredCards.indices.contains(safeIndex) {
            CardFormView(mode: .edit, existingCard: filteredCards[safeIndex], deckTags: deckTags) { card in
                store.updateCard(in: deckID, card: card)
                isFlipped = false; showNotes = false
            }
        }
    }

    // MARK: Gestures
    var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { v in dragOffset = v.translation.width }
            .onEnded { v in
                let th: CGFloat = 60
                if v.translation.width < -th && safeIndex < filteredCards.count - 1 {
                    withAnimation(.spring(response: 0.35)) { dragOffset = 0; isFlipped = false; showNotes = false; currentIndex = safeIndex + 1 }
                    hapticLight()
                } else if v.translation.width > th && safeIndex > 0 {
                    withAnimation(.spring(response: 0.35)) { dragOffset = 0; isFlipped = false; showNotes = false; currentIndex = safeIndex - 1 }
                    hapticLight()
                } else {
                    withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                }
            }
    }

    func deleteCurrentCard() {
        guard filteredCards.indices.contains(safeIndex) else { return }
        store.deleteCard(in: deckID, cardID: filteredCards[safeIndex].id)
        isFlipped = false; showNotes = false
        if currentIndex >= filteredCards.count && currentIndex > 0 { currentIndex = filteredCards.count - 1 }
    }
}


// ============================================================
// MARK: - Flashcard View (Expansive, Centered)
// ============================================================

struct FlashcardView: View {
    let card: Flashcard
    let cardIndex: Int
    @Binding var isFlipped: Bool
    @Binding var showNotes: Bool
    let settings: AppSettings

    private let colorPairs: [(Color, Color)] = [
        (Color(red: 0.92, green: 0.56, blue: 0.62), Color(red: 0.82, green: 0.42, blue: 0.52)),
        (Color(red: 0.58, green: 0.66, blue: 0.92), Color(red: 0.45, green: 0.52, blue: 0.82)),
        (Color(red: 0.55, green: 0.80, blue: 0.68), Color(red: 0.40, green: 0.68, blue: 0.55)),
        (Color(red: 0.90, green: 0.68, blue: 0.50), Color(red: 0.80, green: 0.55, blue: 0.40)),
        (Color(red: 0.74, green: 0.60, blue: 0.88), Color(red: 0.60, green: 0.44, blue: 0.76)),
    ]

    var body: some View {
        let cp = colorPairs[cardIndex % colorPairs.count]
        ZStack {
            answerSide(cp)
            questionSide
        }
        .frame(maxHeight: 560)
        .padding(.horizontal, 16)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isFlipped.toggle()
                showNotes = false
            }
            hapticSoft()
        }
    }

    var questionSide: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(CuteTheme.cardBG)
            .shadow(color: CuteTheme.pink.opacity(0.25), radius: 16, y: 8)
            .overlay(questionContent)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 0 : 1)
    }

    var questionContent: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 16) {
                    Text("QUESTION").font(.system(size: 10, weight: .medium)).tracking(2.5).foregroundStyle(CuteTheme.subtle.opacity(0.35))
                    #if canImport(UIKit)
                    if let rtf = rtfToAttributed(card.questionRTF), rtf.length > 0 {
                        RichTextLabel(attributedText: rtf, textColor: UIColor(settings.questionColor.color))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        questionPlainText
                    }
                    #else
                    questionPlainText
                    #endif
                    mediaBlock(imageData: card.questionImageData, doodleData: card.questionDoodleData)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .frame(minHeight: geo.size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    var questionPlainText: some View {
        Text(card.question)
            .font(.system(size: settings.questionFontSize, weight: .bold, design: settings.resolvedDesign))
            .multilineTextAlignment(.center)
            .foregroundStyle(settings.questionColor.color)
    }

    func answerSide(_ cp: (Color, Color)) -> some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(LinearGradient(colors: [cp.0, cp.1], startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(color: cp.0.opacity(0.3), radius: 16, y: 8)
            .overlay(answerContent)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)
    }

    var answerContent: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 16) {
                    Text("ANSWER").font(.system(size: 10, weight: .medium)).tracking(2.5).foregroundStyle(.white.opacity(0.35))
                    #if canImport(UIKit)
                    if let rtf = rtfToAttributed(card.answerRTF), rtf.length > 0 {
                        RichTextLabel(attributedText: rtf, textColor: UIColor(settings.answerColor.color))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        answerPlainText
                    }
                    #else
                    answerPlainText
                    #endif
                    mediaBlock(imageData: card.answerImageData, doodleData: card.answerDoodleData)
                    notesSection
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .frame(minHeight: geo.size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    var answerPlainText: some View {
        Text(card.answer)
            .font(.system(size: settings.answerFontSize, weight: .bold, design: settings.resolvedDesign))
            .multilineTextAlignment(.center)
            .foregroundStyle(settings.answerColor.color)
    }

    func mediaBlock(imageData: Data?, doodleData: Data?) -> some View {
        VStack(spacing: 8) {
            #if canImport(UIKit)
            if let data = imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if let data = doodleData, let drawing = try? PKDrawing(data: data) {
                let img = drawing.image(from: drawing.bounds, scale: 2.0)
                Image(uiImage: img)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 130)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            #elseif canImport(AppKit)
            if let data = imageData, let img = NSImage(data: data) {
                Image(nsImage: img)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            // Doodle not supported on macOS
            #endif
        }
    }

    var notesSection: some View {
        Group {
            if !card.notes.isEmpty || card.notesRTF != nil {
                VStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.3)) { showNotes.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showNotes ? "Hide Notes" : "Show Notes")
                                .font(.caption2.weight(.medium))
                            Image(systemName: showNotes ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8, weight: .semibold))
                        }
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(.white.opacity(0.12), in: Capsule())
                    }

                    if showNotes {
                        #if canImport(UIKit)
                        if let rtf = rtfToAttributed(card.notesRTF), rtf.length > 0 {
                            RichTextLabel(attributedText: rtf, textColor: UIColor.white.withAlphaComponent(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
                            notesPlainText
                        }
                        #else
                        notesPlainText
                        #endif
                    }
                }
            }
        }
    }

    var notesPlainText: some View {
        Text(card.notes)
            .font(.system(size: 14, design: settings.resolvedDesign))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}


// ============================================================
// MARK: - Dot Indicators
// ============================================================

struct DotIndicators: View {
    let total: Int; let current: Int
    @EnvironmentObject var store: DataStore
    var body: some View {
        let tc = ThemeColors(settings: store.settings)
        HStack(spacing: 5) {
            let max7 = 7
            if total <= max7 {
                ForEach(0..<total, id: \.self) { i in dot(i == current, tc: tc) }
            } else {
                let s = max(0, min(current - 3, total - max7))
                let e = min(s + max7, total)
                if s > 0 { Circle().fill(tc.dotOverflow).frame(width: 4, height: 4) }
                ForEach(s..<e, id: \.self) { i in dot(i == current, tc: tc) }
                if e < total { Circle().fill(tc.dotOverflow).frame(width: 4, height: 4) }
            }
        }.animation(.spring(response: 0.3), value: current)
    }
    func dot(_ active: Bool, tc: ThemeColors) -> some View {
        Circle().fill(active ? CuteTheme.accent : tc.dotInactive)
            .frame(width: active ? 9 : 6, height: active ? 9 : 6)
    }
}

// ============================================================
// MARK: - Card Form View
// ============================================================

enum CardFormMode { case add, edit }

struct CardFormView: View {
    @Environment(\.dismiss) var dismiss
    let mode: CardFormMode
    @State private var questionAttr: NSAttributedString
    @State private var answerAttr: NSAttributedString
    @State private var notesAttr: NSAttributedString
    @State private var tags: [String]
    @State private var newTag = ""
    @State private var qImageData: Data?
    @State private var aImageData: Data?
    @State private var qDoodleData: Data?
    @State private var aDoodleData: Data?
    #if canImport(UIKit)
    @State private var selectedQPhoto: PhotosPickerItem? = nil
    @State private var selectedAPhoto: PhotosPickerItem? = nil
    @State private var showQDoodle = false
    @State private var showADoodle = false
    #endif
    let deckTags: [String]
    var onSave: (Flashcard) -> Void
    private var existingID: UUID?

    init(mode: CardFormMode, existingCard: Flashcard? = nil, deckTags: [String] = [], onSave: @escaping (Flashcard) -> Void) {
        self.mode = mode; self.deckTags = deckTags; self.onSave = onSave

        let defaultFont: PlatformFont = PlatformFont.systemFont(ofSize: 17)
        let smallFont: PlatformFont = PlatformFont.systemFont(ofSize: 15)

        let qAttr: NSAttributedString
        if let rtf = existingCard?.questionRTF, let attr = rtfToAttributed(rtf) { qAttr = attr }
        else { qAttr = NSAttributedString(string: existingCard?.question ?? "", attributes: [.font: defaultFont]) }
        let aAttr: NSAttributedString
        if let rtf = existingCard?.answerRTF, let attr = rtfToAttributed(rtf) { aAttr = attr }
        else { aAttr = NSAttributedString(string: existingCard?.answer ?? "", attributes: [.font: defaultFont]) }
        let nAttr: NSAttributedString
        if let rtf = existingCard?.notesRTF, let attr = rtfToAttributed(rtf) { nAttr = attr }
        else { nAttr = NSAttributedString(string: existingCard?.notes ?? "", attributes: [.font: smallFont]) }

        _questionAttr = State(initialValue: qAttr)
        _answerAttr = State(initialValue: aAttr)
        _notesAttr = State(initialValue: nAttr)
        _tags = State(initialValue: existingCard?.tags ?? [])
        _qImageData = State(initialValue: existingCard?.questionImageData)
        _aImageData = State(initialValue: existingCard?.answerImageData)
        _qDoodleData = State(initialValue: existingCard?.questionDoodleData)
        _aDoodleData = State(initialValue: existingCard?.answerDoodleData)
        self.existingID = existingCard?.id
    }

    var isValid: Bool {
        !attributedToPlain(questionAttr).isEmpty && !attributedToPlain(answerAttr).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    richEditorSection(title: "Question", hint: "", attr: $questionAttr)
                    #if canImport(UIKit)
                    mediaDoodleRow(label: "Question", imageData: $qImageData, doodleData: $qDoodleData, photoPicker: $selectedQPhoto, showDoodle: $showQDoodle)
                    #endif

                    Divider().padding(.vertical, 4)

                    richEditorSection(title: "Answer", hint: "", attr: $answerAttr)
                    #if canImport(UIKit)
                    mediaDoodleRow(label: "Answer", imageData: $aImageData, doodleData: $aDoodleData, photoPicker: $selectedAPhoto, showDoodle: $showADoodle)
                    #endif

                    Divider().padding(.vertical, 4)

                    richEditorSection(title: "Notes (hidden on card)", hint: "", attr: $notesAttr)
                    tagsSection
                }
                .padding()
            }
            #if canImport(UIKit)
            .background(Color(.systemGroupedBackground))
            #else
            .background(Color(.windowBackgroundColor))
            #endif
            .navigationTitle(mode == .add ? "New Card \u{2728}" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { formToolbar }
            #if canImport(UIKit)
            .onChange(of: selectedQPhoto) { item in loadPhoto(item, into: $qImageData) }
            .onChange(of: selectedAPhoto) { item in loadPhoto(item, into: $aImageData) }
            .sheet(isPresented: $showQDoodle) { DoodleSheet(doodleData: $qDoodleData) }
            .sheet(isPresented: $showADoodle) { DoodleSheet(doodleData: $aDoodleData) }
            #endif
        }
    }

    #if canImport(UIKit)
    func mediaDoodleRow(label: String, imageData: Binding<Data?>, doodleData: Binding<Data?>, photoPicker: Binding<PhotosPickerItem?>, showDoodle: Binding<Bool>) -> some View {
        VStack(spacing: 8) {
            if let data = imageData.wrappedValue, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Button("Remove Image", role: .destructive) { imageData.wrappedValue = nil }.font(.caption)
            }
            if let data = doodleData.wrappedValue, let drawing = try? PKDrawing(data: data) {
                let img = drawing.image(from: drawing.bounds, scale: 2.0)
                Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 120)
                    .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                Button("Remove Doodle", role: .destructive) { doodleData.wrappedValue = nil }.font(.caption)
            }
            HStack(spacing: 12) {
                PhotosPicker(selection: photoPicker, matching: .images) {
                    Label(imageData.wrappedValue == nil ? "Image" : "Change", systemImage: "photo")
                        .font(.caption.bold())
                }
                Button { showDoodle.wrappedValue = true } label: {
                    Label(doodleData.wrappedValue == nil ? "Doodle" : "Edit", systemImage: "pencil.tip.crop.circle")
                        .font(.caption.bold())
                }
            }
            .padding(.vertical, 4)
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
    }
    #endif

    func richEditorSection(title: String, hint: String, attr: Binding<NSAttributedString>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.bold()).foregroundStyle(.secondary).padding(.leading, 4)
            RichTextEditorView(attributedText: attr)
                .frame(minHeight: 100)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    var tagsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tags").font(.caption.bold()).foregroundStyle(.secondary).padding(.leading, 4)
            VStack(spacing: 10) {
                if !tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag).font(.caption.bold())
                                Button { tags.removeAll { $0 == tag } } label: {
                                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(CuteTheme.accent.opacity(0.15), in: Capsule())
                            .foregroundStyle(CuteTheme.accent)
                        }
                    }
                }
                HStack {
                    TextField("Add tag...", text: $newTag)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    Button {
                        let t = newTag.trimmingCharacters(in: .whitespaces).lowercased()
                        if !t.isEmpty && !tags.contains(t) { tags.append(t) }
                        newTag = ""
                    } label: { Image(systemName: "plus.circle.fill") }
                        .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                existingTagSuggestions
            }
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder var existingTagSuggestions: some View {
        let unused = deckTags.filter { !tags.contains($0) }
        if !unused.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("Existing:").font(.caption).foregroundStyle(.secondary)
                    ForEach(unused, id: \.self) { tag in
                        Button { if !tags.contains(tag) { tags.append(tag) } } label: {
                            Text(tag).font(.caption).padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder var formToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
            Button(mode == .add ? "Add" : "Save") { saveCard() }.disabled(!isValid)
        }
    }

    func saveCard() {
        var card = Flashcard(
            question: attributedToPlain(questionAttr),
            answer: attributedToPlain(answerAttr),
            notes: attributedToPlain(notesAttr),
            tags: tags,
            questionRTF: attributedToRTF(questionAttr),
            answerRTF: attributedToRTF(answerAttr),
            notesRTF: attributedToRTF(notesAttr),
            questionImageData: qImageData,
            answerImageData: aImageData,
            questionDoodleData: qDoodleData,
            answerDoodleData: aDoodleData
        )
        if let eid = existingID { card.id = eid }
        onSave(card)
        dismiss()
    }

    #if canImport(UIKit)
    func loadPhoto(_ item: PhotosPickerItem?, into binding: Binding<Data?>) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let compressed = compressImage(data) {
                await MainActor.run { binding.wrappedValue = compressed }
            }
        }
    }
    #endif
}

// ============================================================
// MARK: - Doodle (PencilKit with Tool Picker)
// ============================================================

#if canImport(UIKit)
struct DoodleCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .white
        canvas.isOpaque = true
        canvas.overrideUserInterfaceStyle = .light

        let toolPicker = PKToolPicker()
        context.coordinator.toolPicker = toolPicker
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)

        DispatchQueue.main.async {
            canvas.becomeFirstResponder()
        }

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if !context.coordinator.isDrawing && uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DoodleCanvasView
        var toolPicker: PKToolPicker?
        var isDrawing = false

        init(_ p: DoodleCanvasView) { parent = p }

        func canvasViewDrawingDidChange(_ cv: PKCanvasView) {
            isDrawing = true
            parent.drawing = cv.drawing
            isDrawing = false
        }
    }
}

struct DoodleSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var doodleData: Data?
    @State private var drawing = PKDrawing()

    var body: some View {
        NavigationStack {
            DoodleCanvasView(drawing: $drawing)
                .ignoresSafeArea(.container, edges: .bottom)
                .navigationTitle("Draw")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            doodleData = drawing.dataRepresentation()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Button(role: .destructive) {
                                drawing = PKDrawing()
                            } label: {
                                Label("Clear Canvas", systemImage: "trash")
                            }
                            Spacer()
                            Text("Draw with finger or Apple Pencil")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onAppear {
                    if let data = doodleData, let d = try? PKDrawing(data: data) {
                        drawing = d
                    }
                }
        }
    }
}
#endif


// ============================================================
// MARK: - Search View
// ============================================================

enum TagMatchMode: String, CaseIterable { case any = "Any tag", all = "All tags" }
enum SortOption: String, CaseIterable { case newest = "Newest", oldest = "Oldest", alphabetical = "A \u{2192} Z" }

struct SearchCardItem: Identifiable {
    let id = UUID(); let deck: Deck; let card: Flashcard
}
struct SearchEditItem: Identifiable {
    let id = UUID(); let deckID: UUID; let card: Flashcard
}

struct SearchView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @Binding var navPath: NavigationPath
    @State private var query = ""
    @State private var selectedTags: Set<String> = []
    @State private var selectedDecks: Set<UUID> = []
    @State private var tagMatchMode: TagMatchMode = .any
    @State private var sortOption: SortOption = .newest
    @State private var showFilters = false
    @State private var viewingCard: SearchCardItem? = nil
    @State private var editingCard: SearchEditItem? = nil
    @State private var deletingCard: SearchEditItem? = nil
    @State private var showDeleteAlert = false

    var hasActiveFilters: Bool { !selectedTags.isEmpty || !selectedDecks.isEmpty }

    var results: [(Deck, Flashcard)] {
        var m: [(Deck, Flashcard)] = []
        for deck in store.decks {
            if !selectedDecks.isEmpty && !selectedDecks.contains(deck.id) { continue }
            for card in deck.cards {
                let qMatch = query.isEmpty ||
                    card.question.localizedCaseInsensitiveContains(query) ||
                    card.answer.localizedCaseInsensitiveContains(query) ||
                    card.notes.localizedCaseInsensitiveContains(query) ||
                    card.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                let tMatch: Bool
                if selectedTags.isEmpty { tMatch = true }
                else if tagMatchMode == .any { tMatch = !selectedTags.isDisjoint(with: card.tags) }
                else { tMatch = selectedTags.isSubset(of: Set(card.tags)) }
                if qMatch && tMatch { m.append((deck, card)) }
            }
        }
        switch sortOption {
        case .newest: m.sort { $0.1.createdAt > $1.1.createdAt }
        case .oldest: m.sort { $0.1.createdAt < $1.1.createdAt }
        case .alphabetical: m.sort { $0.1.question.localizedCaseInsensitiveCompare($1.1.question) == .orderedAscending }
        }
        return m
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                if showFilters { filterPanel }
                resultsList
            }
            .searchable(text: $query, prompt: "Search everything...")
            .navigationTitle("\u{1F50D} Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    if hasActiveFilters {
                        Button("Clear") { selectedTags.removeAll(); selectedDecks.removeAll(); query = "" }
                    }
                }
            }
            .sheet(item: $viewingCard) { item in CardPreviewSheet(deck: item.deck, card: item.card) }
            .sheet(item: $editingCard) { item in
                let tags = Array(Set(store.decks.first { $0.id == item.deckID }?.cards.flatMap { $0.tags } ?? [])).sorted()
                CardFormView(mode: .edit, existingCard: item.card, deckTags: tags) { store.updateCard(in: item.deckID, card: $0) }
            }
            .alert("Delete card?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let d = deletingCard { store.deleteCard(in: d.deckID, cardID: d.card.id) }
                    deletingCard = nil
                }
                Button("Cancel", role: .cancel) { deletingCard = nil }
            }
        }
    }

    var filterBar: some View {
        HStack(spacing: 10) {
            Button { withAnimation(.spring(response: 0.3)) { showFilters.toggle() } } label: {
                HStack(spacing: 5) {
                    Image(systemName: "line.3.horizontal.decrease.circle\(showFilters ? ".fill" : "")")
                    Text("Filters").font(.subheadline.bold())
                    if hasActiveFilters {
                        Text("\(selectedTags.count + selectedDecks.count)")
                            .font(.caption2.bold()).foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(CuteTheme.accent, in: Capsule())
                    }
                }.foregroundStyle(hasActiveFilters ? CuteTheme.accent : .secondary)
            }
            Spacer()
            Menu {
                ForEach(SortOption.allCases, id: \.self) { o in
                    Button { sortOption = o } label: {
                        HStack { Text(o.rawValue); if sortOption == o { Image(systemName: "checkmark") } }
                    }
                }
            } label: {
                HStack(spacing: 4) { Image(systemName: "arrow.up.arrow.down"); Text(sortOption.rawValue).font(.caption) }.foregroundStyle(.secondary)
            }
            Text("\(results.count)").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.horizontal).padding(.vertical, 10)
    }

    var filterPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Decks").font(.caption.bold()).foregroundStyle(.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(store.decks) { dk in
                        FilterChip(label: "\(dk.name) (\(dk.cards.count))", icon: "\u{1F4DA}", isSelected: selectedDecks.contains(dk.id)) {
                            if selectedDecks.contains(dk.id) { selectedDecks.remove(dk.id) } else { selectedDecks.insert(dk.id) }
                        }
                    }
                }
            }
            if !store.allTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tags").font(.caption.bold()).foregroundStyle(.secondary)
                        Spacer()
                        if selectedTags.count > 1 {
                            Picker("", selection: $tagMatchMode) {
                                ForEach(TagMatchMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }.pickerStyle(.segmented).frame(width: 180)
                        }
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(store.allTags, id: \.self) { tag in
                            FilterChip(label: tag, icon: nil, isSelected: selectedTags.contains(tag)) {
                                if selectedTags.contains(tag) { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
                            }
                        }
                    }
                }
            }
            if hasActiveFilters {
                Button { withAnimation { selectedTags.removeAll(); selectedDecks.removeAll() } } label: {
                    HStack(spacing: 4) { Image(systemName: "xmark.circle.fill"); Text("Clear all") }
                        .font(.caption.bold()).foregroundStyle(.red.opacity(0.8))
                }
            }
        }
        .padding(.horizontal).padding(.bottom, 12)
    }

    var resultsList: some View {
        Group {
            if results.isEmpty {
                VStack(spacing: 12) {
                    Spacer(); Text("\u{1F50D}").font(.system(size: 40))
                    Text(query.isEmpty && !hasActiveFilters ? "Start typing to search" : "No results")
                        .font(.headline).foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(results, id: \.1.id) { deck, card in
                        Button { jumpToCard(deck: deck, card: card) } label: {
                            SearchResultRow(deckName: deck.name, card: card)
                        }
                        .contextMenu {
                            Button { viewingCard = SearchCardItem(deck: deck, card: card) } label: {
                                Label("Quick Preview", systemImage: "eye")
                            }
                            Button { editingCard = SearchEditItem(deckID: deck.id, card: card) } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                deletingCard = SearchEditItem(deckID: deck.id, card: card)
                                showDeleteAlert = true
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }.listStyle(.plain)
            }
        }
    }

    func jumpToCard(deck: Deck, card: Flashcard) {
        store.pendingDeckNav = deck.id
        store.pendingCardID = card.id
        dismiss()
    }
}

struct SearchResultRow: View {
    let deckName: String; let card: Flashcard
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(card.question).font(.subheadline.weight(.semibold))
            Text(card.answer).font(.caption).foregroundStyle(CuteTheme.subtle).lineLimit(2)
            if !card.notes.isEmpty {
                Text(card.notes).font(.caption2).foregroundStyle(.tertiary).lineLimit(1).italic()
            }
            HStack(spacing: 5) {
                Text(deckName).font(.caption2.weight(.medium)).foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(CuteTheme.accent.opacity(0.65), in: Capsule())
                ForEach(card.tags, id: \.self) { tag in
                    Text(tag).font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.gray.opacity(0.06), in: Capsule())
                        .foregroundStyle(CuteTheme.subtle)
                }
            }
        }.padding(.vertical, 3)
    }
}

struct CardPreviewSheet: View {
    let deck: Deck; let card: Flashcard
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var isFlipped = false
    @State private var showNotes = false
    var body: some View {
        NavigationStack {
            ZStack {
                AppBG()
                VStack {
                    Spacer()
                    FlashcardView(card: card, cardIndex: 0, isFlipped: $isFlipped, showNotes: $showNotes, settings: store.settings)
                    Text(deck.name).font(.caption.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(CuteTheme.accent.opacity(0.7), in: Capsule())
                        .padding(.top, 12)
                    Text("Tap to flip").font(.caption).foregroundStyle(.secondary).padding(.top, 4)
                    Spacer()
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}


// ============================================================
// MARK: - Card List
// ============================================================

struct CardListView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let deckID: UUID
    @Binding var currentIndex: Int
    @Binding var isFlipped: Bool
    @Binding var showNotes: Bool
    var deck: Deck? { store.decks.first { $0.id == deckID } }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array((deck?.cards ?? []).enumerated()), id: \.element.id) { index, card in
                    Button { currentIndex = index; isFlipped = false; showNotes = false; dismiss() } label: {
                        HStack(spacing: 12) {
                            Text("\(index + 1)").font(.caption2.weight(.semibold)).foregroundStyle(.white)
                                .frame(width: 26, height: 26).background(CuteTheme.accent.opacity(0.8), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(card.question).font(.subheadline.weight(.medium)).lineLimit(1)
                                Text(card.answer).font(.caption).foregroundStyle(CuteTheme.subtle).lineLimit(1)
                            }
                            Spacer()
                            if index == currentIndex {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(CuteTheme.accent).font(.caption)
                            }
                        }.padding(.vertical, 1)
                    }
                }
                .onDelete { offsets in
                    for o in offsets {
                        if let card = deck?.cards[safe: o] {
                            store.deleteCard(in: deckID, cardID: card.id)
                        }
                    }
                }
            }
            .navigationTitle("All Cards").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { EditButton() }
            }
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// ============================================================
// MARK: - Settings View
// ============================================================

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                backgroundSection
                toolbarSection
                iCloudSection
                Section {
                    Text("These apply to cards without per-card formatting.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                fontSection
                questionSection
                answerSection
                previewSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    // MARK: Background Theme
    var backgroundSection: some View {
        Section("Background") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BGTheme.all, id: \.id) { bg in
                        let isSelected = store.settings.backgroundTheme == bg.id
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: bg.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 62, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(isSelected ? CuteTheme.accent : Color.gray.opacity(0.2), lineWidth: isSelected ? 2.5 : 1)
                                )
                                .shadow(color: isSelected ? CuteTheme.accent.opacity(0.3) : .clear, radius: 4, y: 2)
                            Text(bg.name)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(isSelected ? CuteTheme.accent : CuteTheme.subtle)
                        }
                        .onTapGesture {
                            store.settings.backgroundTheme = bg.id
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Toolbar Customization
    var toolbarSection: some View {
        Section {
            ForEach(store.settings.toolbarActions, id: \.self) { id in
                if let action = AppSettings.allActions.first(where: { $0.id == id }) {
                    HStack(spacing: 10) {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.red.opacity(0.7))
                            .onTapGesture { removeFromToolbar(id) }
                        Image(systemName: action.icon).frame(width: 22)
                            .foregroundStyle(CuteTheme.accent)
                        Text(action.label).font(.subheadline)
                        Spacer()
                    }
                }
            }
            .onMove { from, to in
                store.settings.toolbarActions.move(fromOffsets: from, toOffset: to)
            }

            ForEach(availableActions, id: \.id) { action in
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").foregroundStyle(CuteTheme.accent)
                        .onTapGesture { addToToolbar(action.id) }
                    Image(systemName: action.icon).frame(width: 22)
                        .foregroundStyle(.secondary)
                    Text(action.label).font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                }
            }
        } header: {
            HStack {
                Text("Toolbar")
                Spacer()
                EditButton().font(.caption)
            }
        } footer: {
            Text("Tap + to pin, \u{2212} to remove. Drag to reorder.")
        }
    }

    // MARK: iCloud
    var iCloudSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { store.settings.iCloudSync },
                set: { newVal in
                    if newVal { store.enableICloudSync() }
                    else { store.disableICloudSync() }
                }
            )) {
                HStack(spacing: 10) {
                    Image(systemName: "icloud").foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync").font(.subheadline)
                        Text("Sync decks across devices").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Sync")
        } footer: {
            Text("Keeps your decks and settings in sync across all your Apple devices.")
        }
    }

    var availableActions: [(id: String, label: String, icon: String)] {
        AppSettings.allActions.filter { !store.settings.toolbarActions.contains($0.id) }
    }

    func addToToolbar(_ id: String) {
        if !store.settings.toolbarActions.contains(id) {
            withAnimation { store.settings.toolbarActions.append(id) }
        }
    }

    func removeFromToolbar(_ id: String) {
        withAnimation { store.settings.toolbarActions.removeAll { $0 == id } }
    }

    var fontSection: some View {
        Section("Font Style") {
            Picker("Design", selection: $store.settings.fontDesign) {
                Text("Rounded").tag("rounded")
                Text("Serif").tag("serif")
                Text("Monospaced").tag("monospaced")
                Text("Default").tag("default")
            }
        }
    }

    var questionSection: some View {
        Section("Question Text") {
            HStack {
                Text("Size: \(Int(store.settings.questionFontSize))")
                Slider(value: $store.settings.questionFontSize, in: 14...40, step: 1)
            }
            ColorPicker("Color", selection: questionColorBinding)
        }
    }

    var answerSection: some View {
        Section("Answer Text") {
            HStack {
                Text("Size: \(Int(store.settings.answerFontSize))")
                Slider(value: $store.settings.answerFontSize, in: 14...40, step: 1)
            }
            ColorPicker("Color", selection: answerColorBinding)
        }
    }

    var previewSection: some View {
        Section("Preview") {
            VStack(spacing: 12) {
                Text("Sample Question")
                    .font(.system(size: store.settings.questionFontSize, weight: .bold, design: store.settings.resolvedDesign))
                    .foregroundStyle(store.settings.questionColor.color)
                Divider()
                Text("Sample Answer")
                    .font(.system(size: store.settings.answerFontSize, weight: .bold, design: store.settings.resolvedDesign))
                    .foregroundStyle(store.settings.answerColor.color)
                    .padding(12).frame(maxWidth: .infinity)
                    .background(CuteTheme.accent.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.vertical, 8)
        }
    }

    var questionColorBinding: Binding<Color> {
        Binding(
            get: { store.settings.questionColor.color },
            set: { store.settings.questionColor = CodableColor(color: $0) }
        )
    }
    var answerColorBinding: Binding<Color> {
        Binding(
            get: { store.settings.answerColor.color },
            set: { store.settings.answerColor = CodableColor(color: $0) }
        )
    }
}


// ============================================================
// MARK: - Export View
// ============================================================

struct ExportView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let deckID: UUID
    @State private var exportURL: URL? = nil
    @State private var showShare = false
    var deck: Deck? { store.decks.first { $0.id == deckID } }

    var body: some View {
        NavigationStack {
            List {
                Section("Format") {
                    Button { exportCSV() } label: { Label("CSV", systemImage: "tablecells") }
                    Button { exportJSON() } label: { Label("JSON", systemImage: "doc.text") }
                    #if canImport(UIKit)
                    Button { exportPDF() } label: { Label("PDF", systemImage: "doc.richtext") }
                    #endif
                }
                Section { Text("\(deck?.cards.count ?? 0) cards").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Export").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showShare) {
                if let url = exportURL {
                    #if canImport(UIKit)
                    ShareSheet(url: url)
                    #endif
                }
            }
        }
    }

    func exportCSV() {
        guard let deck = deck else { return }
        var csv = "Question,Answer,Notes,Tags\n"
        for c in deck.cards {
            csv += "\"\(c.question.replacingOccurrences(of: "\"", with: "\"\""))\","
            csv += "\"\(c.answer.replacingOccurrences(of: "\"", with: "\"\""))\","
            csv += "\"\(c.notes.replacingOccurrences(of: "\"", with: "\"\""))\","
            csv += "\"\(c.tags.joined(separator: ";"))\"\n"
        }
        share(csv, "\(deck.name).csv")
    }

    func exportJSON() {
        guard let deck = deck else { return }
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted]
        if let data = try? enc.encode(deck.cards), let json = String(data: data, encoding: .utf8) {
            share(json, "\(deck.name).json")
        }
    }

    #if canImport(UIKit)
    func exportPDF() {
        guard let deck = deck else { return }
        let pw: CGFloat = 612; let ph: CGFloat = 792; let m: CGFloat = 50; let cw = pw - m * 2
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pw, height: ph))
        let data = renderer.pdfData { ctx in
            var y: CGFloat = m
            func newPage() { ctx.beginPage(); y = m }
            func check(_ n: CGFloat) { if y + n > ph - m { newPage() } }
            newPage()
            let title = NSAttributedString(string: deck.name, attributes: [.font: UIFont.boldSystemFont(ofSize: 24)])
            title.draw(at: CGPoint(x: m, y: y)); y += 40
            for (i, card) in deck.cards.enumerated() {
                check(80)
                let num = NSAttributedString(string: "Card \(i+1)", attributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.systemPink])
                num.draw(at: CGPoint(x: m, y: y)); y += 18
                let q = NSAttributedString(string: "Q: \(card.question)", attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
                let qr = q.boundingRect(with: CGSize(width: cw, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                q.draw(in: CGRect(x: m, y: y, width: cw, height: qr.height)); y += qr.height + 6
                let a = NSAttributedString(string: "A: \(card.answer)", attributes: [.font: UIFont.systemFont(ofSize: 13)])
                let ar = a.boundingRect(with: CGSize(width: cw, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                a.draw(in: CGRect(x: m, y: y, width: cw, height: ar.height)); y += ar.height + 4
                if !card.notes.isEmpty {
                    let n = NSAttributedString(string: card.notes, attributes: [.font: UIFont.italicSystemFont(ofSize: 12), .foregroundColor: UIColor.gray])
                    let nr = n.boundingRect(with: CGSize(width: cw, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                    check(nr.height + 4); n.draw(in: CGRect(x: m, y: y, width: cw, height: nr.height)); y += nr.height + 4
                }
                y += 14
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(deck.name).pdf")
        try? data.write(to: url); exportURL = url; showShare = true
    }
    #endif

    func share(_ text: String, _ name: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? text.write(to: url, atomically: true, encoding: .utf8)
        exportURL = url; showShare = true
    }
}

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
#endif


// ============================================================
// MARK: - Import View
// ============================================================

struct ImportView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    var targetDeckID: UUID? = nil

    @State private var showFilePicker = false
    @State private var importedCards: [Flashcard] = []
    @State private var importFileName = ""
    @State private var importError = ""
    @State private var showError = false
    @State private var selectedDeckID: UUID? = nil
    @State private var newDeckName = ""
    @State private var importMode = "existing" // "existing" or "new"

    var body: some View {
        NavigationStack {
            List {
                Section("Source") {
                    Button { showFilePicker = true } label: {
                        Label("Choose File (TXT, CSV, or JSON)", systemImage: "doc.badge.plus")
                    }
                    if !importFileName.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(importFileName).font(.subheadline.weight(.medium))
                                Text("\(importedCards.count) cards found").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if importedCards.isEmpty && importFileName.isEmpty {
                    Section("TXT Format Guide") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type your cards in a .txt file like this:")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("Q: What is the capital of France?\nA: Paris\nN: Western Europe\nT: geography, europe\n\nQ: What is 2 + 2?\nA: 4")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            Text("Q: and A: are required. N: (notes) and T: (tags) are optional. Separate cards with a blank line.")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !importedCards.isEmpty {
                    Section("Destination") {
                        Picker("Import to", selection: $importMode) {
                            Text("Existing Deck").tag("existing")
                            Text("New Deck").tag("new")
                        }.pickerStyle(.segmented)

                        if importMode == "existing" {
                            if store.decks.isEmpty {
                                Text("No decks yet \u{2014} create a new one").font(.caption).foregroundStyle(.secondary)
                            } else {
                                ForEach(store.decks) { deck in
                                    HStack {
                                        Text("\u{1F4DA} \(deck.name)")
                                        Spacer()
                                        if selectedDeckID == deck.id {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(CuteTheme.accent)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedDeckID = deck.id }
                                }
                            }
                        } else {
                            TextField("New deck name", text: $newDeckName)
                        }
                    }

                    Section("Preview") {
                        ForEach(importedCards.prefix(5)) { card in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(card.question).font(.subheadline.weight(.medium)).lineLimit(1)
                                Text(card.answer).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                        if importedCards.count > 5 {
                            Text("... and \(importedCards.count - 5) more")
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                    }

                    Section {
                        Button {
                            performImport()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Import \(importedCards.count) Cards")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .background(canImport ? CuteTheme.accent : Color.gray, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(!canImport)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.commaSeparatedText, .json, .plainText, .text], allowsMultipleSelection: false) { result in
                handleFileImport(result)
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(importError)
            }
            .onAppear {
                if let tid = targetDeckID { selectedDeckID = tid; importMode = "existing" }
            }
        }
    }

    var canImport: Bool {
        if importedCards.isEmpty { return false }
        if importMode == "existing" { return selectedDeckID != nil }
        return !newDeckName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Could not access file"; showError = true; return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                importFileName = url.lastPathComponent

                if url.pathExtension.lowercased() == "json" {
                    if let cards = parseJSONImport(data), !cards.isEmpty {
                        importedCards = cards
                    } else {
                        importError = "Could not parse JSON. Expected array of cards with 'question' and 'answer' fields."; showError = true
                    }
                } else {
                    // CSV, TXT, or plain text
                    guard let text = String(data: data, encoding: .utf8) else {
                        importError = "Could not read file as text"; showError = true; return
                    }

                    // Try plain text Q:/A: format first
                    let txtCards = parsePlainTextImport(text)
                    if !txtCards.isEmpty {
                        importedCards = txtCards
                    } else {
                        // Fall back to CSV
                        let csvCards = parseCSVImport(text)
                        if csvCards.isEmpty {
                            importError = "No valid cards found.\n\nSupported formats:\n\u{2022} Q:/A: format (Q: question\\nA: answer)\n\u{2022} Tab-separated (question[tab]answer)\n\u{2022} CSV with header row"; showError = true
                        } else {
                            importedCards = csvCards
                        }
                    }
                }
            } catch {
                importError = error.localizedDescription; showError = true
            }
        case .failure(let error):
            importError = error.localizedDescription; showError = true
        }
    }

    func performImport() {
        if importMode == "existing", let did = selectedDeckID {
            store.importCards(to: did, cards: importedCards)
        } else if importMode == "new" {
            let name = newDeckName.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return }
            var deck = Deck(name: name)
            deck.cards = importedCards
            store.importDeck(deck)
        }
        dismiss()
    }
}


// ============================================================
// MARK: - Filter Chip
// ============================================================

struct FilterChip: View {
    let label: String; let icon: String?; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Text(icon).font(.caption2) }
                Text(label).font(.caption.bold())
                if isSelected { Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)) }
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(isSelected ? CuteTheme.accent : Color.gray.opacity(0.1), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

struct TagChip: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.caption.bold())
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? CuteTheme.accent : Color.gray.opacity(0.12), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

// ============================================================
// MARK: - Flow Layout
// ============================================================

struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let r = arrange(proposal: proposal, subviews: subviews)
        for (i, p) in r.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }
    struct R { var positions: [CGPoint]; var size: CGSize }
    func arrange(proposal: ProposedViewSize, subviews: Subviews) -> R {
        let mw = proposal.width ?? .infinity
        var pos: [CGPoint] = []; var x: CGFloat = 0; var y: CGFloat = 0; var rh: CGFloat = 0; var mx: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x + sz.width > mw && x > 0 { x = 0; y += rh + spacing; rh = 0 }
            pos.append(CGPoint(x: x, y: y)); rh = max(rh, sz.height); x += sz.width + spacing; mx = max(mx, x)
        }
        return R(positions: pos, size: CGSize(width: mx, height: y + rh))
    }
}
