import SwiftUI
import Combine
import UniformTypeIdentifiers

// ============================================================
// MARK: - Data Models
// ============================================================

struct Flashcard: Identifiable, Codable {
    var id = UUID()
    var question: String
    var answer: String
    var notes: String = ""
    var tags: [String] = []
    var createdAt: Date = Date()
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
    @Published var appTitle: String = "🌸 Flashcards" { didSet { saveTitle() } }
    @Published var activeDeckID: UUID? = nil { didSet { saveActiveDeck() } }

    private let decksKey = "saved_decks_v2"
    private let titleKey = "app_title"
    private let activeDeckKey = "active_deck_id"

    init() {
        loadTitle()
        loadDecks()
        if decks.isEmpty { createSampleDeck() }
        loadActiveDeck()
        if activeDeckID == nil || !decks.contains(where: { $0.id == activeDeckID }) {
            activeDeckID = decks.first?.id
        }
    }

    var activeDeck: Deck? {
        decks.first(where: { $0.id == activeDeckID })
    }

    func createSampleDeck() {
        let cards: [Flashcard] = [
            Flashcard(question: "What is the capital of Japan?", answer: "Tokyo", notes: "Tokyo is the most populous metropolitan area in the world with over 37 million people.", tags: ["geography", "asia"]),
            Flashcard(question: "What is photosynthesis?", answer: "The process plants use to convert sunlight into energy", notes: "Plants absorb CO₂ and water, then use sunlight to produce glucose and oxygen. The chemical equation is 6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂", tags: ["science", "biology"]),
            Flashcard(question: "Who wrote Romeo and Juliet?", answer: "William Shakespeare", notes: "Written around 1594–1596. It's one of his earliest tragedies.", tags: ["literature", "history"]),
            Flashcard(question: "What is the powerhouse of the cell?", answer: "Mitochondria", notes: "Mitochondria generate most of the cell's supply of ATP, used as a source of chemical energy.", tags: ["science", "biology"]),
            Flashcard(question: "What year did World War II end?", answer: "1945", notes: "Germany surrendered in May 1945, Japan in August 1945 after the atomic bombings of Hiroshima and Nagasaki.", tags: ["history"]),
            Flashcard(question: "What is the chemical symbol for gold?", answer: "Au", notes: "From the Latin word 'aurum'. Gold has atomic number 79.", tags: ["science", "chemistry"]),
            Flashcard(question: "What is the largest ocean on Earth?", answer: "Pacific Ocean", notes: "Covers about 165.25 million km² — more than all the land area on Earth combined.", tags: ["geography"]),
            Flashcard(question: "What does CPU stand for?", answer: "Central Processing Unit", notes: "Often called the 'brain' of the computer. It performs instructions from programs.", tags: ["technology"]),
            Flashcard(question: "What is the Pythagorean theorem?", answer: "a² + b² = c²", notes: "In a right triangle, the square of the hypotenuse equals the sum of squares of the other two sides.", tags: ["math"]),
            Flashcard(question: "What planet is known as the Red Planet?", answer: "Mars", notes: "Its reddish appearance is due to iron oxide (rust) on its surface. It has two small moons: Phobos and Deimos.", tags: ["science", "space"]),
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

    func saveTitle() {
        UserDefaults.standard.set(appTitle, forKey: titleKey)
    }

    func loadTitle() {
        if let t = UserDefaults.standard.string(forKey: titleKey) {
            appTitle = t
        }
    }

    func saveActiveDeck() {
        if let id = activeDeckID {
            UserDefaults.standard.set(id.uuidString, forKey: activeDeckKey)
        }
    }

    func loadActiveDeck() {
        if let str = UserDefaults.standard.string(forKey: activeDeckKey),
           let id = UUID(uuidString: str) {
            activeDeckID = id
        }
    }

    // Deck operations
    func addDeck(_ name: String) {
        let deck = Deck(name: name)
        decks.append(deck)
        activeDeckID = deck.id
    }

    func deleteDeck(at index: Int) {
        guard decks.indices.contains(index) else { return }
        let wasActive = decks[index].id == activeDeckID
        decks.remove(at: index)
        if wasActive {
            activeDeckID = decks.first?.id
        }
    }

    func deleteDeck(id: UUID) {
        if let i = decks.firstIndex(where: { $0.id == id }) {
            deleteDeck(at: i)
        }
    }

    func renameDeck(id: UUID, to name: String) {
        if let i = decks.firstIndex(where: { $0.id == id }) {
            decks[i].name = name
        }
    }

    // Card operations within a deck
    func addCard(to deckID: UUID, card: Flashcard) {
        if let i = decks.firstIndex(where: { $0.id == deckID }) {
            decks[i].cards.append(card)
        }
    }

    func updateCard(in deckID: UUID, card: Flashcard) {
        if let di = decks.firstIndex(where: { $0.id == deckID }),
           let ci = decks[di].cards.firstIndex(where: { $0.id == card.id }) {
            decks[di].cards[ci] = card
        }
    }

    func deleteCard(in deckID: UUID, at index: Int) {
        if let di = decks.firstIndex(where: { $0.id == deckID }),
           decks[di].cards.indices.contains(index) {
            decks[di].cards.remove(at: index)
        }
    }

    func shuffleDeck(_ deckID: UUID) {
        if let i = decks.firstIndex(where: { $0.id == deckID }) {
            decks[i].cards.shuffle()
        }
    }

    // All tags across all decks
    var allTags: [String] {
        let tags = decks.flatMap { $0.cards.flatMap { $0.tags } }
        return Array(Set(tags)).sorted()
    }
}

// ============================================================
// MARK: - Theme
// ============================================================

struct CuteTheme {
    static let encouragements = [
        "Amazing! ✨", "You're doing great! 🌟", "So smart! 🐰",
        "Nailed it! 🌸", "Keep going! 💫", "Wonderful! 🦋",
    ]
    static func randomEncouragement() -> String {
        encouragements.randomElement() ?? "Amazing! ✨"
    }

    static let pink = Color(red: 1.0, green: 0.78, blue: 0.82)
    static let softPink = Color(red: 1.0, green: 0.93, blue: 0.95)
    static let cream = Color(red: 1.0, green: 0.98, blue: 0.95)
    static let sky = Color(red: 0.85, green: 0.92, blue: 1.0)
    static let accent = Color(red: 0.82, green: 0.50, blue: 0.62)
}

// ============================================================
// MARK: - App Entry Point
// ============================================================

@main
struct FlashcardApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(store)
        }
    }
}

// ============================================================
// MARK: - Background
// ============================================================

struct AppBackgroundLayer: View {
    var body: some View {
        LinearGradient(
            colors: [CuteTheme.softPink, CuteTheme.cream, CuteTheme.sky.opacity(0.3)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// ============================================================
// MARK: - Main View
// ============================================================

struct MainView: View {
    @EnvironmentObject var store: DataStore
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var showAddCard = false
    @State private var showEditCard = false
    @State private var showDeleteAlert = false
    @State private var showCardList = false
    @State private var showRenameDeck = false
    @State private var showRenameTitle = false
    @State private var showNewDeck = false
    @State private var showExport = false
    @State private var showSearch = false
    @State private var showManageDecks = false
    @State private var newDeckName = ""
    @State private var newTitle = ""
    @State private var dragOffset: CGFloat = 0
    @State private var filterTags: Set<String> = []

    var deckID: UUID? { store.activeDeckID }

    var deck: Deck? { store.activeDeck }

    var filteredCards: [Flashcard] {
        guard let deck = deck else { return [] }
        if filterTags.isEmpty { return deck.cards }
        return deck.cards.filter { card in
            !filterTags.isDisjoint(with: card.tags)
        }
    }

    var deckTags: [String] {
        guard let deck = deck else { return [] }
        return Array(Set(deck.cards.flatMap { $0.tags })).sorted()
    }

    var safeIndex: Int {
        guard !filteredCards.isEmpty else { return 0 }
        return min(currentIndex, filteredCards.count - 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundLayer()

                if store.decks.isEmpty {
                    noDecksView
                } else if filteredCards.isEmpty {
                    deckEmptyView
                } else {
                    cardBrowser
                }
            }
            .navigationTitle(deck?.name ?? store.appTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { mainToolbar }
            .sheet(isPresented: $showAddCard) { addCardSheet }
            .sheet(isPresented: $showEditCard) { editCardSheet }
            .sheet(isPresented: $showSearch) { SearchView() }
            .sheet(isPresented: $showManageDecks) { ManageDecksView() }
            .sheet(isPresented: $showCardList) {
                if let did = deckID {
                    CardListView(deckID: did, currentIndex: $currentIndex, isFlipped: $isFlipped)
                }
            }
            .sheet(isPresented: $showExport) {
                if let did = deckID {
                    ExportView(deckID: did)
                }
            }
            .alert("Delete card? 🥺", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { deleteCurrentCard() }
                Button("Nevermind! 💕", role: .cancel) { }
            } message: {
                Text("This card will be gone forever...")
            }
            .alert("Rename Deck", isPresented: $showRenameDeck) {
                TextField("Deck name", text: $newDeckName)
                Button("Save") {
                    let n = newDeckName.trimmingCharacters(in: .whitespaces)
                    if !n.isEmpty, let did = deckID { store.renameDeck(id: did, to: n) }
                    newDeckName = ""
                }
                Button("Cancel", role: .cancel) { newDeckName = "" }
            }
            .alert("Rename App Title", isPresented: $showRenameTitle) {
                TextField("New title", text: $newTitle)
                Button("Save") {
                    let t = newTitle.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty { store.appTitle = t }
                    newTitle = ""
                }
                Button("Cancel", role: .cancel) { newTitle = "" }
            }
            .alert("New Deck", isPresented: $showNewDeck) {
                TextField("Deck name", text: $newDeckName)
                Button("Create") {
                    let name = newDeckName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty { store.addDeck(name) }
                    newDeckName = ""
                    resetCardState()
                }
                Button("Cancel", role: .cancel) { newDeckName = "" }
            }
            .onChange(of: filterTags) { _ in
                currentIndex = 0; isFlipped = false
            }
            .onChange(of: store.activeDeckID) { _ in
                resetCardState()
            }
        }
    }

    func resetCardState() {
        currentIndex = 0
        isFlipped = false
        filterTags.removeAll()
        dragOffset = 0
    }

    // MARK: - No Decks

    var noDecksView: some View {
        VStack(spacing: 20) {
            HStack(spacing: -8) {
                Text("🐮").font(.system(size: 44)).rotationEffect(.degrees(-10))
                Text("🐰").font(.system(size: 52))
                Text("🐼").font(.system(size: 44)).rotationEffect(.degrees(10))
            }
            Text("No decks yet!")
                .font(.title2.bold()).foregroundStyle(.primary.opacity(0.7))
            Text("Create a deck to start adding flashcards ✨")
                .font(.subheadline).foregroundStyle(.secondary)
            Button { showNewDeck = true } label: {
                HStack(spacing: 8) {
                    Text("✨")
                    Text("Create First Deck").font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28).padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [CuteTheme.pink, Color(red: 0.82, green: 0.55, blue: 0.72)],
                        startPoint: .leading, endPoint: .trailing
                    ), in: Capsule()
                )
                .shadow(color: CuteTheme.pink.opacity(0.4), radius: 10, y: 5)
            }
        }
    }

    // MARK: - Empty Deck

    var deckEmptyView: some View {
        VStack(spacing: 16) {
            if !filterTags.isEmpty {
                Text("No cards with selected tags")
                    .font(.title3.bold()).foregroundStyle(.secondary)
                Button("Clear Filter") { filterTags.removeAll() }
                    .buttonStyle(.borderedProminent)
                    .tint(CuteTheme.accent)
            } else {
                Text("🐣").font(.system(size: 60))
                Text("No cards in this deck yet")
                    .font(.title3.bold()).foregroundStyle(.secondary)
                Button("Add First Card") { showAddCard = true }
                    .buttonStyle(.borderedProminent)
                    .tint(CuteTheme.accent)
            }
        }
    }

    // MARK: - Card Browser

    var cardBrowser: some View {
        VStack(spacing: 20) {
            if !deckTags.isEmpty {
                tagFilterBar
            }

            Spacer()

            FlashcardView(
                card: filteredCards[safeIndex],
                cardIndex: safeIndex,
                isFlipped: $isFlipped
            )
            .offset(x: dragOffset)
            .gesture(swipeGesture)
            .contextMenu {
                Button { showEditCard = true } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    if let did = deckID {
                        store.shuffleDeck(did)
                        currentIndex = 0; isFlipped = false
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            if filteredCards.count > 1 {
                DotIndicators(total: filteredCards.count, current: safeIndex)
            }

            Text("Swipe to browse · Tap to flip · Hold for options")
                .font(.caption).foregroundStyle(.secondary)

            Spacer()
        }
        .onAppear {
            if currentIndex >= filteredCards.count {
                currentIndex = max(filteredCards.count - 1, 0)
            }
        }
    }

    var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(label: "All", isSelected: filterTags.isEmpty) {
                    filterTags.removeAll()
                }
                ForEach(deckTags, id: \.self) { tag in
                    TagChip(label: tag, isSelected: filterTags.contains(tag)) {
                        if filterTags.contains(tag) {
                            filterTags.remove(tag)
                        } else {
                            filterTags.insert(tag)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    var mainToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            // Deck switcher
            Menu {
                // Switch deck
                Section("Switch Deck") {
                    ForEach(store.decks) { d in
                        Button {
                            store.activeDeckID = d.id
                        } label: {
                            HStack {
                                Text(d.name)
                                if d.id == deckID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                Divider()
                Button { showNewDeck = true } label: {
                    Label("New Deck", systemImage: "plus")
                }
                Button { showManageDecks = true } label: {
                    Label("Manage Decks", systemImage: "folder")
                }
                Divider()
                Button { newTitle = store.appTitle; showRenameTitle = true } label: {
                    Label("Rename App Title", systemImage: "textformat")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.stack")
                    if store.decks.count > 1 {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                }
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass")
            }
            if deck != nil {
                Menu {
                    Button { showCardList = true } label: {
                        Label("All Cards", systemImage: "list.bullet.rectangle")
                    }
                    Button { newDeckName = deck?.name ?? ""; showRenameDeck = true } label: {
                        Label("Rename Deck", systemImage: "pencil")
                    }
                    Button { showExport = true } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            Button { showAddCard = true } label: {
                Image(systemName: "plus.circle.fill").font(.title3)
            }
            .tint(CuteTheme.accent)
            .disabled(deck == nil)
        }
    }

    // MARK: - Sheets

    var addCardSheet: some View {
        CardFormView(mode: .add, deckTags: deckTags) { card in
            if let did = deckID {
                store.addCard(to: did, card: card)
                currentIndex = max(filteredCards.count - 1, 0)
                isFlipped = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    @ViewBuilder
    var editCardSheet: some View {
        if filteredCards.indices.contains(safeIndex) {
            CardFormView(mode: .edit, existingCard: filteredCards[safeIndex], deckTags: deckTags) { card in
                if let did = deckID {
                    store.updateCard(in: did, card: card)
                    isFlipped = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    // MARK: - Gestures & Actions

    var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { v in dragOffset = v.translation.width }
            .onEnded { v in
                let threshold: CGFloat = 60
                let maxIndex = filteredCards.count - 1
                if v.translation.width < -threshold && safeIndex < maxIndex {
                    withAnimation(.spring(response: 0.35)) {
                        dragOffset = 0; isFlipped = false; currentIndex = safeIndex + 1
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else if v.translation.width > threshold && safeIndex > 0 {
                    withAnimation(.spring(response: 0.35)) {
                        dragOffset = 0; isFlipped = false; currentIndex = safeIndex - 1
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else {
                    withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                }
            }
    }

    func deleteCurrentCard() {
        guard let deck = deck, let did = deckID, filteredCards.indices.contains(safeIndex) else { return }
        let card = filteredCards[safeIndex]
        if let realIndex = deck.cards.firstIndex(where: { $0.id == card.id }) {
            store.deleteCard(in: did, at: realIndex)
        }
        isFlipped = false
        if currentIndex >= filteredCards.count && currentIndex > 0 {
            currentIndex = filteredCards.count - 1
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}

// ============================================================
// MARK: - Manage Decks Sheet
// ============================================================

struct ManageDecksView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var showNewDeck = false
    @State private var newDeckName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.decks) { deck in
                    HStack(spacing: 14) {
                        Text("📚").font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(deck.name).font(.headline)
                                if deck.id == store.activeDeckID {
                                    Text("Active")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(CuteTheme.accent, in: Capsule())
                                }
                            }
                            Text("\(deck.cards.count) card\(deck.cards.count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            store.activeDeckID = deck.id
                            dismiss()
                        } label: {
                            Text("Switch")
                                .font(.caption.bold())
                                .foregroundStyle(deck.id == store.activeDeckID ? .secondary : CuteTheme.accent)
                        }
                        .disabled(deck.id == store.activeDeckID)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    for offset in offsets {
                        store.deleteDeck(at: offset)
                    }
                }
            }
            .navigationTitle("Manage Decks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    EditButton()
                    Button { showNewDeck = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Deck", isPresented: $showNewDeck) {
                TextField("Deck name", text: $newDeckName)
                Button("Create") {
                    let name = newDeckName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty { store.addDeck(name) }
                    newDeckName = ""
                }
                Button("Cancel", role: .cancel) { newDeckName = "" }
            }
        }
    }
}

// ============================================================
// MARK: - Tag Chip
// ============================================================

struct TagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? CuteTheme.accent : Color.gray.opacity(0.12), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

// ============================================================
// MARK: - Flashcard View (Scrollable)
// ============================================================

struct FlashcardView: View {
    let card: Flashcard
    let cardIndex: Int
    @Binding var isFlipped: Bool

    private let cardColors: [(Color, Color)] = [
        (Color(red: 0.95, green: 0.60, blue: 0.65), Color(red: 0.85, green: 0.45, blue: 0.58)),
        (Color(red: 0.65, green: 0.72, blue: 0.95), Color(red: 0.50, green: 0.58, blue: 0.85)),
        (Color(red: 0.70, green: 0.88, blue: 0.75), Color(red: 0.50, green: 0.75, blue: 0.60)),
        (Color(red: 0.90, green: 0.72, blue: 0.55), Color(red: 0.80, green: 0.58, blue: 0.45)),
        (Color(red: 0.78, green: 0.65, blue: 0.90), Color(red: 0.65, green: 0.48, blue: 0.80)),
    ]

    var body: some View {
        let cp = cardColors[cardIndex % cardColors.count]
        ZStack {
            answerSide(cp: cp)
            questionSide
        }
        .frame(height: 360)
        .padding(.horizontal, 20)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    func answerSide(cp: (Color, Color)) -> some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(LinearGradient(colors: [cp.0, cp.1], startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(color: cp.0.opacity(0.3), radius: 20, y: 10)
            .overlay(
                ScrollView {
                    VStack(spacing: 12) {
                        Text("ANSWER").font(.caption.bold()).tracking(2)
                            .foregroundStyle(.white.opacity(0.5))
                        Text(card.answer)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        if !card.notes.isEmpty {
                            Divider().background(.white.opacity(0.3)).padding(.horizontal, 20)
                            Text(card.notes)
                                .font(.system(size: 15, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        // Tags
                        if !card.tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(card.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(.white.opacity(0.25), in: Capsule())
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(28)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28))
            )
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)
    }

    var questionSide: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(.white)
            .shadow(color: CuteTheme.pink.opacity(0.18), radius: 20, y: 10)
            .overlay(
                ScrollView {
                    VStack(spacing: 12) {
                        Text("QUESTION").font(.caption.bold()).tracking(2)
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text(card.question)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                        if !card.tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(card.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(CuteTheme.pink.opacity(0.2), in: Capsule())
                                        .foregroundStyle(CuteTheme.accent)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(28)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28))
            )
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 0 : 1)
    }
}

// ============================================================
// MARK: - Dot Indicators
// ============================================================

struct DotIndicators: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            let maxDots = 7
            if total <= maxDots {
                ForEach(0..<total, id: \.self) { i in
                    dot(active: i == current)
                }
            } else {
                let start = max(0, min(current - 3, total - maxDots))
                let end = min(start + maxDots, total)
                if start > 0 {
                    Circle().fill(CuteTheme.pink.opacity(0.2)).frame(width: 4, height: 4)
                }
                ForEach(start..<end, id: \.self) { i in
                    dot(active: i == current)
                }
                if end < total {
                    Circle().fill(CuteTheme.pink.opacity(0.2)).frame(width: 4, height: 4)
                }
            }
        }
        .animation(.spring(response: 0.3), value: current)
    }

    func dot(active: Bool) -> some View {
        Circle()
            .fill(active ? CuteTheme.accent : CuteTheme.pink.opacity(0.4))
            .frame(width: active ? 10 : 7, height: active ? 10 : 7)
    }
}

// ============================================================
// MARK: - Card Form (Add / Edit)
// ============================================================

enum CardFormMode { case add, edit }

struct CardFormView: View {
    @Environment(\.dismiss) var dismiss
    let mode: CardFormMode
    @State private var question: String
    @State private var answer: String
    @State private var notes: String
    @State private var tags: [String]
    @State private var newTag: String = ""
    let deckTags: [String]
    var onSave: (Flashcard) -> Void
    private var existingID: UUID?

    init(mode: CardFormMode, existingCard: Flashcard? = nil, deckTags: [String] = [], onSave: @escaping (Flashcard) -> Void) {
        self.mode = mode
        self.deckTags = deckTags
        self.onSave = onSave
        _question = State(initialValue: existingCard?.question ?? "")
        _answer = State(initialValue: existingCard?.answer ?? "")
        _notes = State(initialValue: existingCard?.notes ?? "")
        _tags = State(initialValue: existingCard?.tags ?? [])
        self.existingID = existingCard?.id
    }

    var isValid: Bool {
        !question.trimmingCharacters(in: .whitespaces).isEmpty &&
        !answer.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("Enter question", text: $question, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Answer") {
                    TextField("Enter answer", text: $answer, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Notes (optional)") {
                    TextField("Additional details, hints, context...", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
                Section("Tags") {
                    tagEditor
                    if !deckTags.isEmpty {
                        existingTagSuggestions
                    }
                }
            }
            .navigationTitle(mode == .add ? "New Card ✨" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode == .add ? "Add" : "Save") { saveCard() }
                        .disabled(!isValid)
                }
            }
        }
    }

    var tagEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current tags
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
            // Add new tag
            HStack {
                TextField("Add tag...", text: $newTag)
                    .textInputAutocapitalization(.never)
                Button {
                    let tag = newTag.trimmingCharacters(in: .whitespaces).lowercased()
                    if !tag.isEmpty && !tags.contains(tag) {
                        tags.append(tag)
                    }
                    newTag = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    var existingTagSuggestions: some View {
        let unused = deckTags.filter { !tags.contains($0) }
        return Group {
            if !unused.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text("Existing:").font(.caption).foregroundStyle(.secondary)
                        ForEach(unused, id: \.self) { tag in
                            Button {
                                if !tags.contains(tag) { tags.append(tag) }
                            } label: {
                                Text(tag).font(.caption)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    func saveCard() {
        var card = Flashcard(
            question: question.trimmingCharacters(in: .whitespaces),
            answer: answer.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces),
            tags: tags
        )
        if let eid = existingID { card.id = eid }
        onSave(card)
        dismiss()
    }
}

// ============================================================
// MARK: - Flow Layout (for tags)
// ============================================================

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    struct ArrangeResult {
        var positions: [CGPoint]
        var size: CGSize
    }

    func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxW = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxW && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return ArrangeResult(positions: positions, size: CGSize(width: maxX, height: y + rowHeight))
    }
}

// ============================================================
// MARK: - Card List View
// ============================================================

struct CardListView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let deckID: UUID
    @Binding var currentIndex: Int
    @Binding var isFlipped: Bool

    var deck: Deck? { store.decks.first(where: { $0.id == deckID }) }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array((deck?.cards ?? []).enumerated()), id: \.element.id) { index, card in
                    Button {
                        currentIndex = index
                        isFlipped = false
                        dismiss()
                    } label: {
                        cardRow(index: index, card: card)
                    }
                }
                .onDelete { offsets in
                    for offset in offsets {
                        store.deleteCard(in: deckID, at: offset)
                    }
                    if (deck?.cards.isEmpty ?? true) {
                        currentIndex = 0; dismiss()
                    } else if currentIndex >= (deck?.cards.count ?? 0) {
                        currentIndex = max((deck?.cards.count ?? 1) - 1, 0)
                    }
                }
            }
            .navigationTitle("✨ All Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
    }

    func cardRow(index: Int, card: Flashcard) -> some View {
        HStack(spacing: 14) {
            Text("\(index + 1)")
                .font(.caption.bold()).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(CuteTheme.accent, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(card.question).font(.subheadline.bold()).lineLimit(1)
                HStack(spacing: 4) {
                    Text(card.answer).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    if !card.tags.isEmpty {
                        Text("·").foregroundStyle(.tertiary)
                        Text(card.tags.joined(separator: ", "))
                            .font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                    }
                }
            }
            Spacer()
            if index == currentIndex {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(CuteTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}

// ============================================================
// MARK: - Search View
// ============================================================

enum TagMatchMode: String, CaseIterable {
    case any = "Any tag"
    case all = "All tags"
}

enum SortOption: String, CaseIterable {
    case newest = "Newest"
    case oldest = "Oldest"
    case alphabetical = "A → Z"
}

struct SearchView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
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

    var hasActiveFilters: Bool {
        !selectedTags.isEmpty || !selectedDecks.isEmpty
    }

    var results: [(Deck, Flashcard)] {
        var matches: [(Deck, Flashcard)] = []
        for deck in store.decks {
            if !selectedDecks.isEmpty && !selectedDecks.contains(deck.id) {
                continue
            }
            for card in deck.cards {
                let matchesQuery = query.isEmpty ||
                    card.question.localizedCaseInsensitiveContains(query) ||
                    card.answer.localizedCaseInsensitiveContains(query) ||
                    card.notes.localizedCaseInsensitiveContains(query) ||
                    card.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })

                let matchesTags: Bool
                if selectedTags.isEmpty {
                    matchesTags = true
                } else if tagMatchMode == .any {
                    matchesTags = !selectedTags.isDisjoint(with: card.tags)
                } else {
                    matchesTags = selectedTags.isSubset(of: Set(card.tags))
                }

                if matchesQuery && matchesTags {
                    matches.append((deck, card))
                }
            }
        }

        switch sortOption {
        case .newest:
            matches.sort { $0.1.createdAt > $1.1.createdAt }
        case .oldest:
            matches.sort { $0.1.createdAt < $1.1.createdAt }
        case .alphabetical:
            matches.sort { $0.1.question.localizedCaseInsensitiveCompare($1.1.question) == .orderedAscending }
        }

        return matches
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                if showFilters {
                    filterPanel
                }
                resultsList
            }
            .searchable(text: $query, prompt: "Search questions, answers, notes, tags...")
            .navigationTitle("🔍 Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { searchToolbar }
            .sheet(item: $viewingCard) { item in
                CardPreviewSheet(deck: item.deck, card: item.card)
            }
            .sheet(item: $editingCard) { item in
                let deckTags = Array(Set(store.decks.first(where: { $0.id == item.deckID })?.cards.flatMap { $0.tags } ?? [])).sorted()
                CardFormView(mode: .edit, existingCard: item.card, deckTags: deckTags) { updated in
                    store.updateCard(in: item.deckID, card: updated)
                }
            }
            .alert("Delete card? 🥺", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let d = deletingCard, let deck = store.decks.first(where: { $0.id == d.deckID }),
                       let idx = deck.cards.firstIndex(where: { $0.id == d.card.id }) {
                        store.deleteCard(in: d.deckID, at: idx)
                    }
                    deletingCard = nil
                }
                Button("Nevermind! 💕", role: .cancel) { deletingCard = nil }
            } message: {
                Text("This card will be gone forever...")
            }
        }
    }

    // MARK: - Filter Bar

    var filterBar: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3)) { showFilters.toggle() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "line.3.horizontal.decrease.circle\(showFilters ? ".fill" : "")")
                    Text("Filters")
                        .font(.subheadline.bold())
                    if hasActiveFilters {
                        Text("\(selectedTags.count + selectedDecks.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(CuteTheme.accent, in: Capsule())
                    }
                }
                .foregroundStyle(hasActiveFilters ? CuteTheme.accent : .secondary)
            }

            Spacer()

            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        sortOption = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(sortOption.rawValue).font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal).padding(.vertical, 10)
    }

    // MARK: - Filter Panel

    var filterPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Decks section — always visible
            VStack(alignment: .leading, spacing: 8) {
                Text("Decks").font(.caption.bold()).foregroundStyle(.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(store.decks) { deck in
                        FilterChip(
                            label: "\(deck.name) (\(deck.cards.count))",
                            icon: "📚",
                            isSelected: selectedDecks.contains(deck.id)
                        ) {
                            if selectedDecks.contains(deck.id) {
                                selectedDecks.remove(deck.id)
                            } else {
                                selectedDecks.insert(deck.id)
                            }
                        }
                    }
                }
            }

            // Tags section
            if !store.allTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tags").font(.caption.bold()).foregroundStyle(.secondary)
                        Spacer()
                        if selectedTags.count > 1 {
                            Picker("", selection: $tagMatchMode) {
                                ForEach(TagMatchMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }
                    }

                    FlowLayout(spacing: 6) {
                        ForEach(store.allTags, id: \.self) { tag in
                            FilterChip(
                                label: tag,
                                icon: nil,
                                isSelected: selectedTags.contains(tag)
                            ) {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        }
                    }
                }
            }

            if hasActiveFilters {
                Button {
                    withAnimation {
                        selectedTags.removeAll()
                        selectedDecks.removeAll()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear all filters")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.red.opacity(0.8))
                }
            }
        }
        .padding(.horizontal).padding(.bottom, 12)
        .background(Color(.systemBackground).opacity(0.5))
    }

    // MARK: - Results List

    var resultsList: some View {
        Group {
            if results.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text("🔍").font(.system(size: 40))
                    Text(query.isEmpty && !hasActiveFilters ? "Start typing to search" : "No results found")
                        .font(.headline).foregroundStyle(.secondary)
                    if hasActiveFilters {
                        Text("Try removing some filters")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
            } else {
                List {
                    ForEach(results, id: \.1.id) { deck, card in
                        Button {
                            viewingCard = SearchCardItem(deck: deck, card: card)
                        } label: {
                            SearchResultRow(deck: deck, card: card, query: query, selectedTags: selectedTags)
                        }
                        .contextMenu {
                            Button {
                                editingCard = SearchEditItem(deckID: deck.id, card: card)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button {
                                store.activeDeckID = deck.id
                                dismiss()
                            } label: {
                                Label("Go to Deck", systemImage: "rectangle.stack")
                            }
                            Button(role: .destructive) {
                                deletingCard = SearchEditItem(deckID: deck.id, card: card)
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    var searchToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Done") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
            if hasActiveFilters {
                Button("Clear") {
                    selectedTags.removeAll()
                    selectedDecks.removeAll()
                    query = ""
                }
                .font(.subheadline)
            }
        }
    }
}

// MARK: - Identifiable wrappers for sheet items

struct SearchCardItem: Identifiable {
    let id = UUID()
    let deck: Deck
    let card: Flashcard
}

struct SearchEditItem: Identifiable {
    let id = UUID()
    let deckID: UUID
    let card: Flashcard
}

// MARK: - Card Preview Sheet

struct CardPreviewSheet: View {
    let deck: Deck
    let card: Flashcard
    @Environment(\.dismiss) var dismiss
    @State private var isFlipped = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundLayer()

                VStack(spacing: 24) {
                    Spacer()

                    FlashcardView(
                        card: card,
                        cardIndex: 0,
                        isFlipped: $isFlipped
                    )

                    Text(deck.name)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(CuteTheme.accent.opacity(0.7), in: Capsule())

                    if !card.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(card.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1), in: Capsule())
                            }
                        }
                    }

                    Text("Tap card to flip")
                        .font(.caption).foregroundStyle(.secondary)

                    Spacer()
                }
            }
            .navigationTitle("Card Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Text(icon).font(.caption2)
                }
                Text(label).font(.caption.bold())
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(isSelected ? CuteTheme.accent : Color.gray.opacity(0.1), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let deck: Deck
    let card: Flashcard
    let query: String
    let selectedTags: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Question
            Text(card.question)
                .font(.subheadline.bold())

            // Answer
            Text(card.answer)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Notes preview
            if !card.notes.isEmpty {
                Text(card.notes)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .italic()
            }

            // Deck + Tags
            HStack(spacing: 6) {
                Text(deck.name)
                    .font(.caption2.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(CuteTheme.accent.opacity(0.7), in: Capsule())

                ForEach(card.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(
                            selectedTags.contains(tag)
                                ? CuteTheme.accent.opacity(0.15)
                                : Color.gray.opacity(0.08),
                            in: Capsule()
                        )
                        .foregroundStyle(
                            selectedTags.contains(tag)
                                ? CuteTheme.accent
                                : .secondary
                        )
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// ============================================================
// MARK: - Export View
// ============================================================

struct ExportView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let deckID: UUID
    @State private var showShareSheet = false
    @State private var exportURL: URL? = nil

    var deck: Deck? { store.decks.first(where: { $0.id == deckID }) }

    var body: some View {
        NavigationStack {
            List {
                Section("Export Format") {
                    Button { exportCSV() } label: {
                        Label("Export as CSV", systemImage: "tablecells")
                    }
                    Button { exportJSON() } label: {
                        Label("Export as JSON", systemImage: "doc.text")
                    }
                    Button { exportPDF() } label: {
                        Label("Export as PDF", systemImage: "doc.richtext")
                    }
                }
                Section {
                    Text("\(deck?.cards.count ?? 0) cards will be exported")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Export Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
        }
    }

    func exportCSV() {
        guard let deck = deck else { return }
        var csv = "Question,Answer,Notes,Tags\n"
        for card in deck.cards {
            let q = card.question.replacingOccurrences(of: "\"", with: "\"\"")
            let a = card.answer.replacingOccurrences(of: "\"", with: "\"\"")
            let n = card.notes.replacingOccurrences(of: "\"", with: "\"\"")
            let t = card.tags.joined(separator: ";")
            csv += "\"\(q)\",\"\(a)\",\"\(n)\",\"\(t)\"\n"
        }
        share(data: csv, filename: "\(deck.name).csv")
    }

    func exportJSON() {
        guard let deck = deck else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(deck.cards),
           let json = String(data: data, encoding: .utf8) {
            share(data: json, filename: "\(deck.name).json")
        }
    }

    func exportPDF() {
        guard let deck = deck else { return }
        let pageW: CGFloat = 612
        let pageH: CGFloat = 792
        let margin: CGFloat = 50
        let contentW = pageW - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let data = renderer.pdfData { ctx in
            var y: CGFloat = margin

            func newPage() {
                ctx.beginPage()
                y = margin
            }

            func checkSpace(_ needed: CGFloat) {
                if y + needed > pageH - margin { newPage() }
            }

            newPage()

            // Title
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let titleStr = NSAttributedString(string: deck.name, attributes: titleAttr)
            titleStr.draw(at: CGPoint(x: margin, y: y))
            y += 40

            let qAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14)
            ]
            let aAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13)
            ]
            let nAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]

            for (i, card) in deck.cards.enumerated() {
                checkSpace(80)

                let numStr = NSAttributedString(string: "Card \(i + 1)", attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: UIColor.systemPink
                ])
                numStr.draw(at: CGPoint(x: margin, y: y))
                y += 18

                let qStr = NSAttributedString(string: "Q: \(card.question)", attributes: qAttr)
                let qRect = qStr.boundingRect(with: CGSize(width: contentW, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                qStr.draw(in: CGRect(x: margin, y: y, width: contentW, height: qRect.height))
                y += qRect.height + 6

                let aStr = NSAttributedString(string: "A: \(card.answer)", attributes: aAttr)
                let aRect = aStr.boundingRect(with: CGSize(width: contentW, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                aStr.draw(in: CGRect(x: margin, y: y, width: contentW, height: aRect.height))
                y += aRect.height + 4

                if !card.notes.isEmpty {
                    let noteStr = NSAttributedString(string: card.notes, attributes: nAttr)
                    let nRect = noteStr.boundingRect(with: CGSize(width: contentW, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                    checkSpace(nRect.height + 4)
                    noteStr.draw(in: CGRect(x: margin, y: y, width: contentW, height: nRect.height))
                    y += nRect.height + 4
                }

                if !card.tags.isEmpty {
                    let tagStr = NSAttributedString(string: "Tags: \(card.tags.joined(separator: ", "))", attributes: [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.systemPurple
                    ])
                    tagStr.draw(at: CGPoint(x: margin, y: y))
                    y += 16
                }

                y += 14
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(deck.name).pdf")
        try? data.write(to: url)
        exportURL = url
        showShareSheet = true
    }

    func share(data: String, filename: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url, atomically: true, encoding: .utf8)
        exportURL = url
        showShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
