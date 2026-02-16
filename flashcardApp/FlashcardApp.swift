import SwiftUI

// MARK: - Data Model

struct Flashcard: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - Sample Data

let sampleCards: [Flashcard] = [
    Flashcard(question: "What is the capital of France?", answer: "Paris"),
    Flashcard(question: "What year did the Moon landing happen?", answer: "1969"),
    Flashcard(question: "What is the powerhouse of the cell?", answer: "Mitochondria"),
    Flashcard(question: "Who painted the Mona Lisa?", answer: "Leonardo da Vinci"),
    Flashcard(question: "What is the chemical symbol for gold?", answer: "Au"),
    Flashcard(question: "How many planets are in the solar system?", answer: "8"),
    Flashcard(question: "What language is primarily used for iOS development?", answer: "Swift"),
    Flashcard(question: "What is the largest ocean on Earth?", answer: "Pacific Ocean"),
]

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
    @State private var cards: [Flashcard] = sampleCards
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var knownCount: Int = 0
    @State private var learningCount: Int = 0
    @State private var isFinished: Bool = false

    var progress: Double {
        guard !cards.isEmpty else { return 1.0 }
        return Double(knownCount + learningCount) / Double(cards.count)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if isFinished {
                finishedView
            } else {
                mainView
            }
        }
    }

    // MARK: - Main Card View

    var mainView: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Flashcards")
                    .font(.largeTitle.bold())
                Spacer()
                Text("\(currentIndex + 1)/\(cards.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Progress Bar
            ProgressView(value: progress)
                .tint(.blue)
                .padding(.horizontal)

            // Score
            HStack(spacing: 32) {
                Label("\(knownCount)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
                Label("\(learningCount)", systemImage: "arrow.counterclockwise.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.headline)
            }

            Spacer()

            // Card
            if currentIndex < cards.count {
                cardView(for: cards[currentIndex])
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                handleSwipe(value.translation)
                            }
                    )
                    .animation(.spring(response: 0.4), value: dragOffset)
            }

            Spacer()

            // Instructions
            HStack {
                VStack {
                    Image(systemName: "arrow.left")
                    Text("Still Learning")
                        .font(.caption)
                }
                .foregroundStyle(.orange)

                Spacer()

                Text("Tap to flip")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                VStack {
                    Image(systemName: "arrow.right")
                    Text("Got It!")
                        .font(.caption)
                }
                .foregroundStyle(.green)
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
        }
        .padding(.top)
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
        .frame(height: 300)
        .padding(.horizontal, 24)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.35)) {
                isFlipped.toggle()
            }
        }
    }

    // MARK: - Finished View

    var finishedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("All Done!")
                .font(.largeTitle.bold())

            VStack(spacing: 8) {
                Text("✅ Known: \(knownCount)")
                    .font(.title3)
                Text("🔄 Still Learning: \(learningCount)")
                    .font(.title3)
            }
            .padding()

            Button {
                resetDeck()
            } label: {
                Label("Start Over", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Logic

    func handleSwipe(_ translation: CGSize) {
        if translation.width > 100 {
            // Swipe right → known
            knownCount += 1
            advanceCard()
        } else if translation.width < -100 {
            // Swipe left → still learning
            learningCount += 1
            advanceCard()
        } else {
            dragOffset = .zero
        }
    }

    func advanceCard() {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(
                width: dragOffset.width > 0 ? 500 : -500,
                height: 0
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dragOffset = .zero
            isFlipped = false
            if currentIndex + 1 < cards.count {
                currentIndex += 1
            } else {
                isFinished = true
            }
        }
    }

    func resetDeck() {
        currentIndex = 0
        knownCount = 0
        learningCount = 0
        isFlipped = false
        isFinished = false
        cards.shuffle()
    }
}
