import SwiftUI
import Combine

// MARK: - Data Model

struct Flashcard: Identifiable, Codable {
    var id = UUID()
    var question: String
    var answer: String
    var createdAt: Date = Date()
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

    func add(_ card: Flashcard) {
        cards.append(card)
    }

    func update(_ card: Flashcard) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        }
    }

    func delete(at index: Int) {
        guard cards.indices.contains(index) else { return }
        cards.remove(at: index)
    }

    func shuffle() {
        cards.shuffle()
    }
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
    @State private var cardTransition: Edge = .trailing

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.93, green: 0.89, blue: 1.0),
                        Color(red: 0.85, green: 0.82, blue: 0.97)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if store.cards.isEmpty {
                    emptyView
                } else {
                    cardBrowser
                }
            }
            .navigationTitle("Flashcards")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !store.cards.isEmpty {
                        Button {
                            showingListView = true
                        } label: {
                            Image(systemName: "list.bullet.rectangle")
                        }
                    }
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !store.cards.isEmpty {
                        Text("\(currentIndex + 1) / \(store.cards.count)")
                            .font(.subheadline.bold())
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                CardFormView(mode: .add) { question, answer in
                    store.add(Flashcard(question: question, answer: answer))
                    currentIndex = store.cards.count - 1
                    isFlipped = false
                    haptic(.success)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if store.cards.indices.contains(currentIndex) {
                    let card = store.cards[currentIndex]
                    CardFormView(mode: .edit, initialQuestion: card.question, initialAnswer: card.answer) { question, answer in
                        var updated = card
                        updated.question = question
                        updated.answer = answer
                        store.update(updated)
                        isFlipped = false
                        haptic(.success)
                    }
                }
            }
            .sheet(isPresented: $showingListView) {
                CardListView(currentIndex: $currentIndex, isFlipped: $isFlipped)
            }
            .alert("Delete Card", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { deleteCurrentCard() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this card?")
            }
        }
    }

    // MARK: - Empty State

    var emptyView: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.5))
                    .frame(width: 100, height: 70)
                    .rotationEffect(.degrees(-8))
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.7))
                    .frame(width: 100, height: 70)
                    .rotationEffect(.degrees(4))
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .frame(width: 100, height: 70)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
            }

            Text("No flashcards yet")
                .font(.title2.bold())
                .foregroundStyle(.primary.opacity(0.7))

            Text("Create your first card to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showingAddSheet = true
            } label: {
                Label("Create Card", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.55, green: 0.4, blue: 0.95),
                                     Color(red: 0.4, green: 0.3, blue: 0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Card Browser

    var cardBrowser: some View {
        VStack(spacing: 24) {
            Spacer()

            // Card with swipe gesture
            cardView(for: store.cards[currentIndex])
                .offset(x: dragOffset)
                .gesture(
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
                                haptic(.light)
                            } else if value.translation.width > threshold && currentIndex > 0 {
                                withAnimation(.spring(response: 0.35)) {
                                    dragOffset = 0
                                    isFlipped = false
                                    currentIndex -= 1
                                }
                                haptic(.light)
                            } else {
                                withAnimation(.spring(response: 0.3)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )

            // Dot indicators (show up to 7)
            if store.cards.count > 1 {
                dotIndicators
            }

            // Actions
            HStack(spacing: 16) {
                actionButton(icon: "shuffle", label: "Shuffle", color: .purple) {
                    store.shuffle()
                    currentIndex = 0
                    isFlipped = false
                    haptic(.medium)
                }

                actionButton(icon: "pencil", label: "Edit", color: .blue) {
                    showingEditSheet = true
                }

                actionButton(icon: "trash", label: "Delete", color: .red) {
                    showingDeleteAlert = true
                }
            }
            .padding(.horizontal)

            Text("Swipe or tap to flip")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Spacer()
        }
    }

    // MARK: - Dot Indicators

    var dotIndicators: some View {
        HStack(spacing: 6) {
            let totalCards = store.cards.count
            let maxDots = 7

            if totalCards <= maxDots {
                ForEach(0..<totalCards, id: \.self) { i in
                    Circle()
                        .fill(i == currentIndex ? Color(red: 0.5, green: 0.35, blue: 0.9) : Color.gray.opacity(0.3))
                        .frame(width: i == currentIndex ? 10 : 7, height: i == currentIndex ? 10 : 7)
                        .animation(.spring(response: 0.3), value: currentIndex)
                }
            } else {
                // Show sliding window of dots
                let start = max(0, min(currentIndex - 3, totalCards - maxDots))
                let end = min(start + maxDots, totalCards)

                if start > 0 {
                    Circle().fill(Color.gray.opacity(0.2)).frame(width: 4, height: 4)
                }

                ForEach(start..<end, id: \.self) { i in
                    Circle()
                        .fill(i == currentIndex ? Color(red: 0.5, green: 0.35, blue: 0.9) : Color.gray.opacity(0.3))
                        .frame(width: i == currentIndex ? 10 : 7, height: i == currentIndex ? 10 : 7)
                        .animation(.spring(response: 0.3), value: currentIndex)
                }

                if end < totalCards {
                    Circle().fill(Color.gray.opacity(0.2)).frame(width: 4, height: 4)
                }
            }
        }
    }

    // MARK: - Action Button

    func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.caption2.bold())
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Card View

    func cardView(for card: Flashcard) -> some View {
        ZStack {
            // Back (answer)
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.55, green: 0.4, blue: 0.95),
                                 Color(red: 0.4, green: 0.3, blue: 0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.5, green: 0.35, blue: 0.9).opacity(0.35), radius: 24, y: 12)
                .overlay(
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.4))
                        Text(card.answer)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                    }
                )
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)

            // Front (question)
            RoundedRectangle(cornerRadius: 28)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 24, y: 12)
                .overlay(
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundStyle(.purple.opacity(0.3))
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
        .frame(height: 360)
        .padding(.horizontal, 20)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
            haptic(.soft)
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
        haptic(.rigid)
    }

    // MARK: - Haptics

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
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
                        HStack(spacing: 14) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(red: 0.5, green: 0.35, blue: 0.9), in: Circle())

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
                                    .foregroundStyle(Color(red: 0.5, green: 0.35, blue: 0.9))
                            }
                        }
                        .padding(.vertical, 4)
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
            .navigationTitle("All Cards")
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

    var title: String {
        mode == .add ? "New Card" : "Edit Card"
    }

    var buttonLabel: String {
        mode == .add ? "Add" : "Save"
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(buttonLabel) {
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
