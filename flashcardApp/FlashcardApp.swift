import SwiftUI
import Combine

// MARK: - Data Model

struct Flashcard: Identifiable, Codable {
    var id = UUID()
    var question: String
    var answer: String
    var createdAt: Date = Date()
}

// MARK: - Cute Theme

struct CuteTheme {
    static let encouragements = [
        "Amazing! ✨",
        "You're doing great! 🌟",
        "So smart! 🐰",
        "Nailed it! 🌸",
        "Keep going! 💫",
        "Wonderful! 🦋",
    ]

    static func randomEncouragement() -> String {
        encouragements.randomElement() ?? "Amazing! ✨"
    }

    static let pink = Color(red: 1.0, green: 0.78, blue: 0.82)
    static let softPink = Color(red: 1.0, green: 0.93, blue: 0.95)
    static let peach = Color(red: 1.0, green: 0.89, blue: 0.82)
    static let lilac = Color(red: 0.90, green: 0.85, blue: 1.0)
    static let mint = Color(red: 0.82, green: 0.96, blue: 0.92)
    static let cream = Color(red: 1.0, green: 0.98, blue: 0.95)
    static let sky = Color(red: 0.85, green: 0.92, blue: 1.0)
}

// MARK: - Storage

class CardStore: ObservableObject {
    @Published var cards: [Flashcard] = [] {
        didSet { save() }
    }

    private let key = "saved_flashcards"

    init() { load() }

    func save() {
        if let data = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Flashcard].self, from: data) {
            cards = decoded
        }
    }

    func add(_ card: Flashcard) { cards.append(card) }

    func update(_ card: Flashcard) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        }
    }

    func delete(at index: Int) {
        guard cards.indices.contains(index) else { return }
        cards.remove(at: index)
    }

    func shuffle() { cards.shuffle() }
}

// MARK: - App Entry Point

@main
struct FlashcardApp: App {
    @StateObject private var store = CardStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

// MARK: - Floating Accent

struct FloatingAccent: View {
    let emoji: String
    let size: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let index: Int

    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        Text(emoji)
            .font(.system(size: size))
            .opacity(opacity)
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(.degrees(rotation))
            .position(x: startX, y: startY)
            .onAppear {
                let dur = 2.5 + Double(index % 7) * 0.5
                let dir: CGFloat = index % 2 == 0 ? 1 : -1
                withAnimation(
                    .easeInOut(duration: dur)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.15)
                ) {
                    yOffset = dir * CGFloat(6 + (index * 3) % 12)
                    xOffset = -dir * CGFloat(3 + (index * 5) % 8)
                    opacity = 0.25 + Double(index % 5) * 0.06
                    rotation = Double(-10 + (index * 7) % 20)
                }
            }
    }
}

struct FloatingEmojiData: Identifiable {
    let id: Int
    let emoji: String
    let size: CGFloat
    let xFraction: CGFloat
    let yFraction: CGFloat
}

struct FloatingEmojisView: View {
    let items: [FloatingEmojiData]

    init() {
        let emojis = [
            "🌸", "☁️", "✨", "🌷", "💫", "🦋", "🐰", "🐮",
            "🐼", "🍓", "🌈", "💕", "🐧", "🍰", "🐑", "🌻",
            "🐥", "🍡", "☀️", "🐷", "🧁", "🌺", "🦊", "💐",
            "🌙", "🐻", "🍩", "⭐", "🌿", "🐝", "🎀", "🍪",
            "🐣", "🌼", "🐾", "🎈", "🐨", "🍬", "☘️", "🧸",
            "💛", "🌴", "🐇", "🪻", "🩵", "🍀", "🫖", "🎐"
        ]

        let cols = 6
        let rows = 8

        let cellW = 1.0 / CGFloat(cols)
        let cellH = 1.0 / CGFloat(rows)

        var generated: [FloatingEmojiData] = []
        var emojiIndex = 0

        for row in 0..<rows {
            for col in 0..<cols {
                guard emojiIndex < emojis.count else { break }

                let jitterX = CGFloat((emojiIndex * 173 + 67) % 100) / 100.0 * 0.6 + 0.2
                let jitterY = CGFloat((emojiIndex * 239 + 43) % 100) / 100.0 * 0.6 + 0.2

                let xf = (CGFloat(col) + jitterX) * cellW
                let yf = (CGFloat(row) + jitterY) * cellH

                let size = CGFloat(17 + (emojiIndex * 31 + 7) % 13)

                generated.append(FloatingEmojiData(
                    id: emojiIndex,
                    emoji: emojis[emojiIndex],
                    size: size,
                    xFraction: xf,
                    yFraction: yf
                ))
                emojiIndex += 1
            }
        }

        self.items = generated
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ForEach(items) { item in
                FloatingAccent(
                    emoji: item.emoji,
                    size: item.size,
                    startX: item.xFraction * w,
                    startY: item.yFraction * h,
                    index: item.id
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Floating Encouragement Words

struct FloatingWord: View {
    let text: String
    let startX: CGFloat
    let startY: CGFloat
    let index: Int

    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.75, green: 0.55, blue: 0.70))
            .opacity(opacity)
            .offset(y: yOffset)
            .rotationEffect(.degrees(rotation))
            .position(x: startX, y: startY)
            .onAppear {
                let dur = 3.0 + Double(index % 5) * 0.7
                let dir: CGFloat = index % 2 == 0 ? 1 : -1
                withAnimation(
                    .easeInOut(duration: dur)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.3)
                ) {
                    yOffset = dir * CGFloat(5 + index % 8)
                    opacity = 0.12 + Double(index % 4) * 0.03
                    rotation = Double(-6 + (index * 3) % 12)
                }
            }
    }
}

struct FloatingWordsData: Identifiable {
    let id: Int
    let text: String
    let xFraction: CGFloat
    let yFraction: CGFloat
}

struct FloatingWordsView: View {
    let items: [FloatingWordsData]

    init() {
        let words = [
            "you got this!", "keep going ♡", "so smart!", "doing great!",
            "amazing!", "believe!", "you're a star ☆", "almost there!",
            "don't give up!", "wonderful!", "so proud ♡", "go go go!"
        ]

        let cols = 3
        let rows = 4
        let cellW = 1.0 / CGFloat(cols)
        let cellH = 1.0 / CGFloat(rows)

        var generated: [FloatingWordsData] = []
        var wordIndex = 0

        for row in 0..<rows {
            for col in 0..<cols {
                guard wordIndex < words.count else { break }

                let jitterX = CGFloat((wordIndex * 211 + 89) % 100) / 100.0 * 0.5 + 0.25
                let jitterY = CGFloat((wordIndex * 167 + 53) % 100) / 100.0 * 0.5 + 0.25

                let xf = (CGFloat(col) + jitterX) * cellW
                let yf = (CGFloat(row) + jitterY) * cellH

                generated.append(FloatingWordsData(
                    id: wordIndex,
                    text: words[wordIndex],
                    xFraction: xf,
                    yFraction: yf
                ))
                wordIndex += 1
            }
        }

        self.items = generated
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ForEach(items) { item in
                FloatingWord(
                    text: item.text,
                    startX: item.xFraction * w,
                    startY: item.yFraction * h,
                    index: item.id
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: -8) {
                Text("🐮").font(.system(size: 44)).rotationEffect(.degrees(-10))
                Text("🐰").font(.system(size: 52))
                Text("🐼").font(.system(size: 44)).rotationEffect(.degrees(10))
            }

            Text("No cards yet!")
                .font(.title2.bold())
                .foregroundStyle(.primary.opacity(0.7))

            Text("Let's make some adorable flashcards ✨")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Text("✨")
                    Text("Create First Card")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [CuteTheme.pink, Color(red: 0.82, green: 0.55, blue: 0.72)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(color: CuteTheme.pink.opacity(0.4), radius: 10, y: 5)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Single Card View

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
        let colorPair = cardColors[cardIndex % cardColors.count]

        ZStack {
            answerSide(colorPair: colorPair)
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

    func answerSide(colorPair: (Color, Color)) -> some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(
                LinearGradient(
                    colors: [colorPair.0, colorPair.1],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: colorPair.0.opacity(0.3), radius: 20, y: 10)
            .overlay(
                VStack(spacing: 12) {
                    Text("ANSWER")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(card.answer)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                }
            )
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)
    }

    var questionSide: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(.white)
            .shadow(color: CuteTheme.pink.opacity(0.18), radius: 20, y: 10)
            .overlay(
                VStack(spacing: 12) {
                    Text("QUESTION")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text(card.question)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 28)
                }
            )
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 0 : 1)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.subheadline.bold())
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Dot Indicators

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
            .fill(active ? Color(red: 0.82, green: 0.50, blue: 0.62) : CuteTheme.pink.opacity(0.4))
            .frame(width: active ? 10 : 7, height: active ? 10 : 7)
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var store: CardStore
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var showingAddSheet: Bool = false
    @State private var showingEditSheet: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var showingListView: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var showEncouragement: Bool = false
    @State private var encouragementText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient only
                LinearGradient(
                    colors: [
                        CuteTheme.softPink,
                        CuteTheme.cream,
                        CuteTheme.sky.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Emojis and words float above background but behind cards
                FloatingEmojisView()
                    .ignoresSafeArea()
                FloatingWordsView()
                    .ignoresSafeArea()

                if store.cards.isEmpty {
                    EmptyStateView { showingAddSheet = true }
                } else {
                    cardBrowser
                }

                encouragementOverlay
            }
            .navigationTitle("🌸 Flashcards")
            .toolbar { toolbarItems }
            .sheet(isPresented: $showingAddSheet) { addSheet }
            .sheet(isPresented: $showingEditSheet) { editSheet }
            .sheet(isPresented: $showingListView) {
                CardListView(currentIndex: $currentIndex, isFlipped: $isFlipped)
            }
            .alert("Remove this card? 🥺", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { deleteCurrentCard() }
                Button("Nevermind! 💕", role: .cancel) { }
            } message: {
                Text("This card will be gone forever...")
            }
        }
    }

    // MARK: - Encouragement Overlay

    var encouragementOverlay: some View {
        Group {
            if showEncouragement {
                Text(encouragementText)
                    .font(.title3.bold())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if !store.cards.isEmpty {
                Button { showingListView = true } label: {
                    Image(systemName: "list.bullet.rectangle")
                }
            }
            Button { showingAddSheet = true } label: {
                Image(systemName: "plus.circle.fill").font(.title3)
            }
            .tint(Color(red: 0.85, green: 0.50, blue: 0.60))
        }
        ToolbarItem(placement: .topBarLeading) {
            if !store.cards.isEmpty {
                Text("\(currentIndex + 1)/\(store.cards.count)")
                    .font(.subheadline.bold())
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Sheets

    var addSheet: some View {
        CardFormView(mode: .add) { question, answer in
            store.add(Flashcard(question: question, answer: answer))
            currentIndex = store.cards.count - 1
            isFlipped = false
            showEncouragementPopup()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    @ViewBuilder
    var editSheet: some View {
        if store.cards.indices.contains(currentIndex) {
            let card = store.cards[currentIndex]
            CardFormView(mode: .edit, initialQuestion: card.question, initialAnswer: card.answer) { question, answer in
                var updated = card
                updated.question = question
                updated.answer = answer
                store.update(updated)
                isFlipped = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    // MARK: - Card Browser

    var cardBrowser: some View {
        VStack(spacing: 24) {
            Spacer()

            FlashcardView(
                card: store.cards[currentIndex],
                cardIndex: currentIndex,
                isFlipped: $isFlipped
            )
            .offset(x: dragOffset)
            .gesture(swipeGesture)

            if store.cards.count > 1 {
                DotIndicators(total: store.cards.count, current: currentIndex)
            }

            HStack(spacing: 12) {
                ActionButton(icon: "shuffle", label: "Shuffle", color: Color(red: 0.55, green: 0.45, blue: 0.70)) {
                    store.shuffle()
                    currentIndex = 0
                    isFlipped = false
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                ActionButton(icon: "pencil", label: "Edit", color: Color(red: 0.35, green: 0.55, blue: 0.75)) {
                    showingEditSheet = true
                }
                ActionButton(icon: "trash", label: "Delete", color: Color(red: 0.80, green: 0.35, blue: 0.35)) {
                    showingDeleteAlert = true
                }
            }
            .padding(.horizontal)

            Text("Swipe to browse · Tap to flip ✨")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Spacer()
        }
    }

    // MARK: - Swipe Gesture

    var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 60
                if value.translation.width < -threshold && currentIndex < store.cards.count - 1 {
                    withAnimation(.spring(response: 0.35)) {
                        dragOffset = 0
                        isFlipped = false
                        currentIndex += 1
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else if value.translation.width > threshold && currentIndex > 0 {
                    withAnimation(.spring(response: 0.35)) {
                        dragOffset = 0
                        isFlipped = false
                        currentIndex -= 1
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Actions

    func deleteCurrentCard() {
        store.delete(at: currentIndex)
        isFlipped = false
        if store.cards.isEmpty {
            currentIndex = 0
        } else if currentIndex >= store.cards.count {
            currentIndex = store.cards.count - 1
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    func showEncouragementPopup() {
        encouragementText = CuteTheme.randomEncouragement()
        withAnimation(.spring(response: 0.4)) {
            showEncouragement = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showEncouragement = false
            }
        }
    }
}

// MARK: - Card List View

struct CardListView: View {
    @EnvironmentObject var store: CardStore
    @Environment(\.dismiss) var dismiss
    @Binding var currentIndex: Int
    @Binding var isFlipped: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(store.cards.enumerated()), id: \.element.id) { index, card in
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
                        store.delete(at: offset)
                    }
                    if store.cards.isEmpty {
                        currentIndex = 0
                        dismiss()
                    } else if currentIndex >= store.cards.count {
                        currentIndex = store.cards.count - 1
                    }
                }
            }
            .navigationTitle("✨ All Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    func cardRow(index: Int, card: Flashcard) -> some View {
        HStack(spacing: 14) {
            Text("\(index + 1)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color(red: 0.82, green: 0.55, blue: 0.65), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(card.question)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(card.answer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if index == currentIndex {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(red: 0.82, green: 0.55, blue: 0.65))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add / Edit Card View

enum CardFormMode {
    case add, edit
}

struct CardFormView: View {
    @Environment(\.dismiss) var dismiss
    let mode: CardFormMode
    @State private var question: String
    @State private var answer: String
    var onSave: (String, String) -> Void

    init(mode: CardFormMode, initialQuestion: String = "", initialAnswer: String = "", onSave: @escaping (String, String) -> Void) {
        self.mode = mode
        _question = State(initialValue: initialQuestion)
        _answer = State(initialValue: initialAnswer)
        self.onSave = onSave
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
            }
            .navigationTitle(mode == .add ? "New Card ✨" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode == .add ? "Add" : "Save") {
                        onSave(question.trimmingCharacters(in: .whitespaces),
                               answer.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty ||
                              answer.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
