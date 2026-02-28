import SwiftUI
import Combine
import PencilKit
import PhotosUI
import UniformTypeIdentifiers

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
        let c = UIColor(color)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r); self.green = Double(g); self.blue = Double(b); self.alpha = Double(a)
    }
}

struct AppSettings: Codable, Equatable {
    var fontDesign: String = "rounded"
    var questionFontSize: CGFloat = 22
    var answerFontSize: CGFloat = 26
    var questionColor: CodableColor = .darkGray
    var answerColor: CodableColor = .white
    var toolbarActions: [String] = ["search", "edit", "add"] // Pinned to top bar

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
    ]
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
        // Legacy keys
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
        // Try new keys first, fall back to legacy
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
// MARK: - Data Store
// ============================================================

class DataStore: ObservableObject {
    @Published var decks: [Deck] = [] { didSet { save() } }
    @Published var appTitle: String = "🌸 Flashcards" { didSet { UserDefaults.standard.set(appTitle, forKey: "app_title") } }
    @Published var settings: AppSettings = AppSettings() { didSet { saveSettings() } }
    @Published var pendingDeckNav: UUID? = nil
    @Published var pendingCardID: UUID? = nil

    private let decksKey = "saved_decks_v3"

    init() {
        if let t = UserDefaults.standard.string(forKey: "app_title") { appTitle = t }
        loadSettings()
        loadDecks()
        if decks.isEmpty { createSampleDeck() }
    }

    func createSampleDeck() {
        let cards: [Flashcard] = [
            Flashcard(question: "What is the capital of Japan?", answer: "Tokyo", notes: "Tokyo is the most populous metropolitan area in the world with over 37 million people.", tags: ["geography", "asia"]),
            Flashcard(question: "What is photosynthesis?", answer: "The process plants use to convert sunlight into energy", notes: "6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂", tags: ["science", "biology"]),
            Flashcard(question: "Who wrote Romeo and Juliet?", answer: "William Shakespeare", notes: "Written around 1594–1596.", tags: ["literature", "history"]),
            Flashcard(question: "What is the powerhouse of the cell?", answer: "Mitochondria", notes: "Generates most of the cell's ATP supply.", tags: ["science", "biology"]),
            Flashcard(question: "What year did World War II end?", answer: "1945", notes: "Germany in May, Japan in August after Hiroshima and Nagasaki.", tags: ["history"]),
            Flashcard(question: "Chemical symbol for gold?", answer: "Au", notes: "From Latin 'aurum'. Atomic number 79.", tags: ["science", "chemistry"]),
            Flashcard(question: "Largest ocean on Earth?", answer: "Pacific Ocean", notes: "165.25 million km² — more than all land combined.", tags: ["geography"]),
            Flashcard(question: "What does CPU stand for?", answer: "Central Processing Unit", notes: "The 'brain' of the computer.", tags: ["technology"]),
            Flashcard(question: "Pythagorean theorem?", answer: "a² + b² = c²", notes: "For right triangles only.", tags: ["math"]),
            Flashcard(question: "Which planet is the Red Planet?", answer: "Mars", notes: "Red from iron oxide. Moons: Phobos and Deimos.", tags: ["science", "space"]),
        ]
        decks.append(Deck(name: "Study Starter Pack", cards: cards))
    }

    func save() {
        if let data = try? JSONEncoder().encode(decks) {
            UserDefaults.standard.set(data, forKey: decksKey)
        }
    }

    func loadDecks() {
        if let data = UserDefaults.standard.data(forKey: decksKey),
           let decoded = try? JSONDecoder().decode([Deck].self, from: data) {
            decks = decoded
        }
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "app_settings")
        }
    }

    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "app_settings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }

    // Deck ops
    func addDeck(_ name: String) { decks.append(Deck(name: name)) }
    func deleteDeck(id: UUID) { decks.removeAll { $0.id == id } }
    func renameDeck(id: UUID, to name: String) {
        if let i = idx(id) { decks[i].name = name }
    }

    // Card ops
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

    var allTags: [String] {
        Array(Set(decks.flatMap { $0.cards.flatMap { $0.tags } })).sorted()
    }

    private func idx(_ did: UUID) -> Int? { decks.firstIndex(where: { $0.id == did }) }
}

// ============================================================
// MARK: - Helpers
// ============================================================

struct CuteTheme {
    static let pink = Color(red: 1.0, green: 0.78, blue: 0.82)
    static let softPink = Color(red: 1.0, green: 0.93, blue: 0.95)
    static let cream = Color(red: 1.0, green: 0.98, blue: 0.95)
    static let sky = Color(red: 0.85, green: 0.92, blue: 1.0)
    static let accent = Color(red: 0.82, green: 0.50, blue: 0.62)
}

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
// MARK: - Rich Text Editor (UIViewRepresentable)
// ============================================================

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

// ============================================================
// MARK: - Rich Text Display
// ============================================================

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
        // Ensure wrapping within parent width
        uiView.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 120
    }
}

// ============================================================
// MARK: - App Entry
// ============================================================

@main
struct FlashcardApp: App {
    @StateObject private var store = DataStore()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
        }
    }
}

// ============================================================
// MARK: - Background
// ============================================================

struct AppBG: View {
    var body: some View {
        LinearGradient(
            colors: [CuteTheme.softPink, CuteTheme.cream, CuteTheme.sky.opacity(0.3)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ).ignoresSafeArea()
    }
}

// ============================================================
// MARK: - Home View (Deck List Landing)
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
                ToolbarItem(placement: .principal) {
                    Button { newTitle = store.appTitle; showRenameTitle = true } label: {
                        Text(store.appTitle)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                    }
                }
            }
            .toolbar { homeToolbar }
            .navigationDestination(for: UUID.self) { deckID in
                DeckView(deckID: deckID)
            }
            .sheet(isPresented: $showSearch) { SearchView(navPath: $navPath) }
            .sheet(isPresented: $showSettings) { SettingsView() }
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
                Text("🐮").font(.system(size: 44)).rotationEffect(.degrees(-10))
                Text("🐰").font(.system(size: 52))
                Text("🐼").font(.system(size: 44)).rotationEffect(.degrees(10))
            }
            Text("No decks yet!").font(.title2.bold()).foregroundStyle(.secondary)
            Button { showNewDeck = true } label: {
                HStack { Text("✨"); Text("Create First Deck").font(.headline) }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(LinearGradient(colors: [CuteTheme.pink, CuteTheme.accent], startPoint: .leading, endPoint: .trailing), in: Capsule())
                    .shadow(color: CuteTheme.pink.opacity(0.4), radius: 10, y: 5)
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
        HStack(spacing: 14) {
            Text("📚").font(.title)
                .frame(width: 50, height: 50)
                .background(CuteTheme.pink.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name).font(.headline).foregroundStyle(.primary)
                Text("\(deck.cards.count) card\(deck.cards.count == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: CuteTheme.pink.opacity(0.12), radius: 8, y: 4)
    }

    @ToolbarContentBuilder
    var homeToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { showSearch = true } label: { Image(systemName: "magnifyingglass") }
            Button { showSettings = true } label: { Image(systemName: "gearshape") }
            Button { showNewDeck = true } label: {
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
        .navigationTitle(deck?.name ?? "Deck")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { deckToolbar }
        .sheet(isPresented: $showAddCard) { addSheet }
        .sheet(isPresented: $showEditCard) { editSheet }
        .sheet(isPresented: $showSearch) { SearchView(navPath: .constant(NavigationPath())) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showCardList) {
            CardListView(deckID: deckID, currentIndex: $currentIndex, isFlipped: $isFlipped, showNotes: $showNotes)
        }
        .sheet(isPresented: $showExport) { ExportView(deckID: deckID) }
        .sheet(isPresented: $showTagFilter) { tagFilterSheet }
        .alert("Delete card? 🥺", isPresented: $showDeleteAlert) {
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
        VStack(spacing: 16) {
            if !filterTags.isEmpty {
                Text("No cards match filters").font(.title3.bold()).foregroundStyle(.secondary)
                Button("Clear") { filterTags.removeAll() }.buttonStyle(.borderedProminent).tint(CuteTheme.accent)
            } else {
                Text("🐣").font(.system(size: 60))
                Text("No cards yet").font(.title3.bold()).foregroundStyle(.secondary)
                Button("Add Card") { showAddCard = true }.buttonStyle(.borderedProminent).tint(CuteTheme.accent)
            }
        }
    }

    // MARK: Card Browser
    var cardBrowser: some View {
        VStack(spacing: 0) {
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
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(CuteTheme.accent)
            Text("\(filterTags.count) tag\(filterTags.count == 1 ? "" : "s") active")
                .font(.caption.bold()).foregroundStyle(CuteTheme.accent)
            Spacer()
            Button("Clear") { filterTags.removeAll() }
                .font(.caption.bold()).foregroundStyle(.red.opacity(0.7))
        }
        .padding(.horizontal).padding(.vertical, 8)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { showTagFilter = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
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
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case "filter": showTagFilter = true
        case "list": showCardList = true
        case "add": showAddCard = true
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
        ToolbarItemGroup(placement: .topBarTrailing) {
            ForEach(pinnedActions, id: \.self) { id in
                if id == "add" {
                    Button { toolbarAction(id) } label: {
                        Image(systemName: iconFor(id)).font(.title3)
                    }.tint(CuteTheme.accent)
                } else {
                    Button { toolbarAction(id) } label: {
                        Image(systemName: iconFor(id))
                    }
                }
            }
            Menu {
                // Overflow actions not pinned
                ForEach(overflowActions, id: \.self) { id in
                    if let action = AppSettings.allActions.first(where: { $0.id == id }) {
                        Button { toolbarAction(id) } label: {
                            Label(action.label, systemImage: action.icon)
                        }
                    }
                }
                Divider()
                Button { newDeckName = deck?.name ?? ""; showRenameDeck = true } label: { Label("Rename Deck", systemImage: "character.cursor.ibeam") }
                Button { showExport = true } label: { Label("Export", systemImage: "square.and.arrow.up") }
                Button { showSettings = true } label: { Label("Settings", systemImage: "gearshape") }
                Divider()
                Button(role: .destructive) { showDeleteAlert = true } label: { Label("Delete Card", systemImage: "trash") }
            } label: { Image(systemName: "ellipsis.circle") }
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
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else if v.translation.width > th && safeIndex > 0 {
                    withAnimation(.spring(response: 0.35)) { dragOffset = 0; isFlipped = false; showNotes = false; currentIndex = safeIndex - 1 }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        (Color(red: 0.95, green: 0.60, blue: 0.65), Color(red: 0.85, green: 0.45, blue: 0.58)),
        (Color(red: 0.65, green: 0.72, blue: 0.95), Color(red: 0.50, green: 0.58, blue: 0.85)),
        (Color(red: 0.70, green: 0.88, blue: 0.75), Color(red: 0.50, green: 0.75, blue: 0.60)),
        (Color(red: 0.90, green: 0.72, blue: 0.55), Color(red: 0.80, green: 0.58, blue: 0.45)),
        (Color(red: 0.78, green: 0.65, blue: 0.90), Color(red: 0.65, green: 0.48, blue: 0.80)),
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
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    // MARK: Question Side
    var questionSide: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(.white)
            .shadow(color: CuteTheme.pink.opacity(0.18), radius: 20, y: 10)
            .overlay(questionContent)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 0 : 1)
    }

    var questionContent: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 16) {
                    Text("QUESTION").font(.caption.bold()).tracking(2).foregroundStyle(.secondary.opacity(0.4))
                    if let rtf = rtfToAttributed(card.questionRTF), rtf.length > 0 {
                        RichTextLabel(attributedText: rtf, textColor: UIColor(settings.questionColor.color))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(card.question)
                            .font(.system(size: settings.questionFontSize, weight: .bold, design: settings.resolvedDesign))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(settings.questionColor.color)
                    }
                    mediaBlock(imageData: card.questionImageData, doodleData: card.questionDoodleData)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .frame(minHeight: geo.size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    // MARK: Answer Side
    func answerSide(_ cp: (Color, Color)) -> some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(LinearGradient(colors: [cp.0, cp.1], startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(color: cp.0.opacity(0.3), radius: 20, y: 10)
            .overlay(answerContent)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)
    }

    var answerContent: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 16) {
                    Text("ANSWER").font(.caption.bold()).tracking(2).foregroundStyle(.white.opacity(0.4))
                    if let rtf = rtfToAttributed(card.answerRTF), rtf.length > 0 {
                        RichTextLabel(attributedText: rtf, textColor: UIColor(settings.answerColor.color))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(card.answer)
                            .font(.system(size: settings.answerFontSize, weight: .bold, design: settings.resolvedDesign))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(settings.answerColor.color)
                    }
                    mediaBlock(imageData: card.answerImageData, doodleData: card.answerDoodleData)
                    notesSection
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .frame(minHeight: geo.size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    // MARK: Media Block
    func mediaBlock(imageData: Data?, doodleData: Data?) -> some View {
        VStack(spacing: 10) {
            if let data = imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            if let data = doodleData, let drawing = try? PKDrawing(data: data) {
                let img = drawing.image(from: drawing.bounds, scale: 2.0)
                Image(uiImage: img)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 140)
                    .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: Hidden Notes
    var notesSection: some View {
        Group {
            if !card.notes.isEmpty || card.notesRTF != nil {
                VStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.3)) { showNotes.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showNotes ? "Hide Notes" : "Show Notes")
                                .font(.caption.bold())
                            Image(systemName: showNotes ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(.white.opacity(0.15), in: Capsule())
                    }

                    if showNotes {
                        if let rtf = rtfToAttributed(card.notesRTF), rtf.length > 0 {
                            RichTextLabel(attributedText: rtf, textColor: UIColor.white.withAlphaComponent(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
                            Text(card.notes)
                                .font(.system(size: 14, design: settings.resolvedDesign))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
            }
        }
    }
}

// ============================================================
// MARK: - Dot Indicators
// ============================================================

struct DotIndicators: View {
    let total: Int; let current: Int
    var body: some View {
        HStack(spacing: 6) {
            let max7 = 7
            if total <= max7 {
                ForEach(0..<total, id: \.self) { i in dot(i == current) }
            } else {
                let s = max(0, min(current - 3, total - max7))
                let e = min(s + max7, total)
                if s > 0 { Circle().fill(CuteTheme.pink.opacity(0.2)).frame(width: 4, height: 4) }
                ForEach(s..<e, id: \.self) { i in dot(i == current) }
                if e < total { Circle().fill(CuteTheme.pink.opacity(0.2)).frame(width: 4, height: 4) }
            }
        }.animation(.spring(response: 0.3), value: current)
    }
    func dot(_ active: Bool) -> some View {
        Circle().fill(active ? CuteTheme.accent : CuteTheme.pink.opacity(0.4))
            .frame(width: active ? 10 : 7, height: active ? 10 : 7)
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
    @State private var selectedQPhoto: PhotosPickerItem? = nil
    @State private var selectedAPhoto: PhotosPickerItem? = nil
    @State private var showQDoodle = false
    @State private var showADoodle = false
    let deckTags: [String]
    var onSave: (Flashcard) -> Void
    private var existingID: UUID?

    init(mode: CardFormMode, existingCard: Flashcard? = nil, deckTags: [String] = [], onSave: @escaping (Flashcard) -> Void) {
        self.mode = mode; self.deckTags = deckTags; self.onSave = onSave

        let qAttr: NSAttributedString
        if let rtf = existingCard?.questionRTF, let attr = rtfToAttributed(rtf) { qAttr = attr }
        else { qAttr = NSAttributedString(string: existingCard?.question ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17)]) }
        let aAttr: NSAttributedString
        if let rtf = existingCard?.answerRTF, let attr = rtfToAttributed(rtf) { aAttr = attr }
        else { aAttr = NSAttributedString(string: existingCard?.answer ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17)]) }
        let nAttr: NSAttributedString
        if let rtf = existingCard?.notesRTF, let attr = rtfToAttributed(rtf) { nAttr = attr }
        else { nAttr = NSAttributedString(string: existingCard?.notes ?? "", attributes: [.font: UIFont.systemFont(ofSize: 15)]) }

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
                    mediaDoodleRow(label: "Question", imageData: $qImageData, doodleData: $qDoodleData, photoPicker: $selectedQPhoto, showDoodle: $showQDoodle)

                    Divider().padding(.vertical, 4)

                    richEditorSection(title: "Answer", hint: "", attr: $answerAttr)
                    mediaDoodleRow(label: "Answer", imageData: $aImageData, doodleData: $aDoodleData, photoPicker: $selectedAPhoto, showDoodle: $showADoodle)

                    Divider().padding(.vertical, 4)

                    richEditorSection(title: "Notes (hidden on card)", hint: "", attr: $notesAttr)
                    tagsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(mode == .add ? "New Card ✨" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { formToolbar }
            .onChange(of: selectedQPhoto) { item in loadPhoto(item, into: $qImageData) }
            .onChange(of: selectedAPhoto) { item in loadPhoto(item, into: $aImageData) }
            .sheet(isPresented: $showQDoodle) { DoodleSheet(doodleData: $qDoodleData) }
            .sheet(isPresented: $showADoodle) { DoodleSheet(doodleData: $aDoodleData) }
        }
    }

    func mediaDoodleRow(label: String, imageData: Binding<Data?>, doodleData: Binding<Data?>, photoPicker: Binding<PhotosPickerItem?>, showDoodle: Binding<Bool>) -> some View {
        VStack(spacing: 8) {
            // Image preview
            if let data = imageData.wrappedValue, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Button("Remove Image", role: .destructive) { imageData.wrappedValue = nil }.font(.caption)
            }
            // Doodle preview
            if let data = doodleData.wrappedValue, let drawing = try? PKDrawing(data: data) {
                let img = drawing.image(from: drawing.bounds, scale: 2.0)
                Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 120)
                    .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                Button("Remove Doodle", role: .destructive) { doodleData.wrappedValue = nil }.font(.caption)
            }
            // Buttons row
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
                    TextField("Add tag...", text: $newTag).textInputAutocapitalization(.never)
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

    func loadPhoto(_ item: PhotosPickerItem?, into binding: Binding<Data?>) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let compressed = compressImage(data) {
                await MainActor.run { binding.wrappedValue = compressed }
            }
        }
    }
}

// ============================================================
// MARK: - Doodle (PencilKit with Tool Picker)
// ============================================================

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

        // Show the full Apple Notes-style tool picker
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
        // Only update if change came from SwiftUI (e.g. clear button), not from user drawing
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

// ============================================================
// MARK: - Search View
// ============================================================

enum TagMatchMode: String, CaseIterable { case any = "Any tag", all = "All tags" }
enum SortOption: String, CaseIterable { case newest = "Newest", oldest = "Oldest", alphabetical = "A → Z" }

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
            .navigationTitle("🔍 Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
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
                        FilterChip(label: "\(dk.name) (\(dk.cards.count))", icon: "📚", isSelected: selectedDecks.contains(dk.id)) {
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
                    Spacer(); Text("🔍").font(.system(size: 40))
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
        VStack(alignment: .leading, spacing: 6) {
            Text(card.question).font(.subheadline.bold())
            Text(card.answer).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            if !card.notes.isEmpty {
                Text(card.notes).font(.caption2).foregroundStyle(.tertiary).lineLimit(1).italic()
            }
            HStack(spacing: 6) {
                Text(deckName).font(.caption2.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(CuteTheme.accent.opacity(0.7), in: Capsule())
                ForEach(card.tags, id: \.self) { tag in
                    Text(tag).font(.caption2)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.gray.opacity(0.08), in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }
        }.padding(.vertical, 4)
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
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } } }
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
                        HStack(spacing: 14) {
                            Text("\(index + 1)").font(.caption.bold()).foregroundStyle(.white)
                                .frame(width: 28, height: 28).background(CuteTheme.accent, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(card.question).font(.subheadline.bold()).lineLimit(1)
                                Text(card.answer).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if index == currentIndex {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(CuteTheme.accent)
                            }
                        }.padding(.vertical, 2)
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
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
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
                toolbarSection
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
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } } }
        }
    }

    // MARK: Toolbar Customization
    var toolbarSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("In Toolbar").font(.caption.bold()).foregroundStyle(.secondary)
                if store.settings.toolbarActions.isEmpty {
                    Text("No actions pinned").font(.caption).foregroundStyle(.tertiary)
                } else {
                    ForEach(store.settings.toolbarActions, id: \.self) { id in
                        if let action = AppSettings.allActions.first(where: { $0.id == id }) {
                            HStack(spacing: 10) {
                                Image(systemName: action.icon).frame(width: 22)
                                    .foregroundStyle(CuteTheme.accent)
                                Text(action.label).font(.subheadline)
                                Spacer()
                                Button { removeFromToolbar(id) } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(.red.opacity(0.7))
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onMove { from, to in
                        store.settings.toolbarActions.move(fromOffsets: from, toOffset: to)
                    }
                }

                if !availableActions.isEmpty {
                    Divider()
                    Text("In ⋯ Menu").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(availableActions, id: \.id) { action in
                        HStack(spacing: 10) {
                            Image(systemName: action.icon).frame(width: 22)
                                .foregroundStyle(.secondary)
                            Text(action.label).font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                            Button { addToToolbar(action.id) } label: {
                                Image(systemName: "plus.circle.fill").foregroundStyle(CuteTheme.accent)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        } header: {
            HStack {
                Text("Toolbar")
                Spacer()
                EditButton().font(.caption)
            }
        } footer: {
            Text("Tap + to pin actions to the toolbar. Tap − to move back to menu. Drag to reorder.")
        }
    }

    var availableActions: [(id: String, label: String, icon: String)] {
        AppSettings.allActions.filter { !store.settings.toolbarActions.contains($0.id) }
    }

    func addToToolbar(_ id: String) {
        if store.settings.toolbarActions.count < 5 && !store.settings.toolbarActions.contains(id) {
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
                    Button { exportPDF() } label: { Label("PDF", systemImage: "doc.richtext") }
                }
                Section { Text("\(deck?.cards.count ?? 0) cards").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Export").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showShare) {
                if let url = exportURL { ShareSheet(url: url) }
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

    func share(_ text: String, _ name: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? text.write(to: url, atomically: true, encoding: .utf8)
        exportURL = url; showShare = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
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
