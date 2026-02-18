import SwiftUI

// MARK: - Data Model

struct Flashcard: Identifiable {
    let id = UUID()
    var question: String
    var answer: String
}

// MARK: - App Entry Point

@main
struct FlashcardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var cards: [Flashcard] = []
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var showingAddSheet: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.91, green: 0.87, blue: 0.97)
                    .ignoresSafeArea()

                if cards.isEmpty {
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
                    if !cards.isEmpty {
                        Text("\(currentIndex + 1) / \(cards.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCardView { question, answer in
                    cards.append(Flashcard(question: question, answer: answer))
                    if cards.count == 1 { currentIndex = 0 }
                }
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
            cardView(for: cards[currentIndex])

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
                        .foregroundStyle(currentIndex < cards.count - 1 ? .blue : .gray.opacity(0.3))
                }
                .disabled(currentIndex >= cards.count - 1)
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
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                .overlay(
                    VStack(spacing: 12) {
                        Text("ANSWER")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(card.answer)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                )
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)

            // Front (question)
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                .overlay(
                    VStack(spacing: 12) {
                        Text("QUESTION")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(card.question)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                )
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
        }
        .frame(height: 280)
        .padding(.horizontal, 24)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.35)) {
                isFlipped.toggle()
            }
        }
    }

    // MARK: - Navigation

    func goToNext() {
        guard currentIndex < cards.count - 1 else { return }
        isFlipped = false
        currentIndex += 1
    }

    func goToPrevious() {
        guard currentIndex > 0 else { return }
        isFlipped = false
        currentIndex -= 1
    }
}

// MARK: - Add Card View

struct AddCardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var question: String = ""
    @State private var answer: String = ""
    var onAdd: (String, String) -> Void

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
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(question.trimmingCharacters(in: .whitespaces),
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
