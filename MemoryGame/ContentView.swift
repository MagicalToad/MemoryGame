import SwiftUI

struct Card: Identifiable {
    let id = UUID()
    let content: String
    var isFaceUp = false
    var isMatched = false
}

class MemoryGameViewModel: ObservableObject {
    @Published private(set) var cards: [Card]
    @Published var score = 0
    @Published var moves = 0
    
    private var indexOfFaceUpCard: Int?
    
    init() {
        let emojis = ["🐶", "🐱", "🐭", "🐹", "🦊", "🐻", "🐼", "🐨"]
        var pairedCards = (emojis + emojis).shuffled().map { Card(content: $0) }
        self.cards = pairedCards
    }
    
    func choose(_ card: Card) {
        if let chosenIndex = cards.firstIndex(where: { $0.id == card.id }), !cards[chosenIndex].isFaceUp, !cards[chosenIndex].isMatched {
            moves += 1
            
            if let potentialMatchIndex = indexOfFaceUpCard {
                if cards[chosenIndex].content == cards[potentialMatchIndex].content {
                    cards[chosenIndex].isMatched = true
                    cards[potentialMatchIndex].isMatched = true
                    score += 10
                }
                indexOfFaceUpCard = nil
            } else {
                indexOfFaceUpCard = chosenIndex
            }
            
            cards[chosenIndex].isFaceUp.toggle()
        }
    }
    
    func restartGame() {
        score = 0
        moves = 0
        let emojis = ["🐶", "🐱", "🐭", "🐹", "🦊", "🐻", "🐼", "🐨"]
        cards = (emojis + emojis).shuffled().map { Card(content: $0) }
        indexOfFaceUpCard = nil
    }
}

struct ContentView: View {
    @StateObject var viewModel = MemoryGameViewModel()
    
    let columns = [GridItem(.adaptive(minimum: 80))]
    
    var body: some View {
        VStack {
            Text("Memory Match Game").font(.largeTitle)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.cards) { card in
                    CardView(card: card)
                        .onTapGesture { viewModel.choose(card) }
                }
            }
            .padding()
            
            HStack {
                Text("Score: \(viewModel.score)")
                Spacer()
                Text("Moves: \(viewModel.moves)")
            }
            .padding()
            
            Button("Restart Game") { viewModel.restartGame() }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .padding()
    }
}

struct CardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 80, height: 100)
                    .overlay(Text(card.content).font(.largeTitle))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .frame(width: 80, height: 100)
            }
        }
        .shadow(radius: 3)
        .animation(.easeInOut, value: card.isFaceUp)
    }
}

@main
struct MemoryMatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
