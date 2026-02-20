import SwiftUI
import Combine

// MARK: - Data Model

struct Flashcard: Identifiable, Codable {
    var id = UUID()
    var question: String
    var answer: String
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

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.91, green: 0.87, blue: 0.97)
                    .ignoresSafeArea()

                if store.cards.isEmpty {
                    emptyView
                } else {
                    cardBrowser
                }
            }
            .navigationTitle("Flashcards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                CardFormView(mode: .add) { question, answer in
                    store.add(Flashcard(question: question, answer: answer))
                    if store.cards.count == 1 { currentIndex = 0 }
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
                    }
                }
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
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("No flashcards yet")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Add Your First Card") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Card Browser

    var cardBrowser: some View {
        VStack(spacing: 32) {
            Spacer()

            // Card
            cardView(for: store.cards[currentIndex])

            // Navigation
            HStack(spacing: 40) {
                Button {
                    goToPrevious()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(currentIndex > 0 ? .blue : .gray.opacity(0.3))
                }
                .disabled(currentIndex == 0)

                Button {
                    goToNext()
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(currentIndex < store.cards.count - 1 ? .blue : .gray.opacity(0.3))
                }
                .disabled(currentIndex >= store.cards.count - 1)
            }

            // Actions
            HStack(spacing: 24) {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.blue.opacity(0.1), in: Capsule())
                }

                Button {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.red.opacity(0.1), in: Capsule())
                }
            }

            Text("Tap card to flip")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
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
                .shadow(color: Color(red: 0.5, green: 0.35, blue: 0.9).opacity(0.4), radius: 20, y: 10)
                .overlay(
                    VStack(spacing: 16) {
                        Text("ANSWER")
                            .font(.caption.bold())
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(card.answer)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                    }
                )
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)

            // Front (question)
            RoundedRectangle(cornerRadius: 28)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                .overlay(
                    VStack(spacing: 16) {
                        Text("QUESTION")
                            .font(.caption.bold())
                            .tracking(2)
                            .foregroundStyle(.secondary)
                        Text(card.question)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 24)
                    }
                )
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
        }
        .frame(height: 380)
        .padding(.horizontal, 20)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.35)) {
                isFlipped.toggle()
            }
        }
    }

    // MARK: - Actions

    func goToNext() {
        guard currentIndex < store.cards.count - 1 else { return }
        isFlipped = false
        currentIndex += 1
    }

    func goToPrevious() {
        guard currentIndex > 0 else { return }
        isFlipped = false
        currentIndex -= 1
    }

    func deleteCurrentCard() {
        store.delete(at: currentIndex)
        isFlipped = false
        if store.cards.isEmpty {
            currentIndex = 0
        } else if currentIndex >= store.cards.count {
            currentIndex = store.cards.count - 1
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
