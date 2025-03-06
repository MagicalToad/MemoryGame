import SwiftUI

struct Card: Identifiable {
    let id = UUID()
    let emoji: String
    var isFaceUp = false
    var isMatched = false
    var position: CGSize = .zero
}

class MemoryGameViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var score: Int = 0
    @Published var moves: Int = 0
    @Published var gameOver: Bool = false
    
    private var firstCardChosen: Card?
    
    let emojis = ["🐶", "🐱", "🐭", "🐹", "🦊", "🐻", "🐼", "🐨"]
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        let pairs = (emojis + emojis).shuffled()
        cards = pairs.map { Card(emoji: $0) }
        
        score = 0
        moves = 0
        gameOver = false
        firstCardChosen = nil
    }
    
    func shuffleCards() {
        cards.shuffle()
    }
    
    func selectCard(_ card: Card) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }),
              !cards[index].isMatched,
              !cards[index].isFaceUp else { return }
        
        if let firstCard = firstCardChosen {
            moves += 1
            cards[index].isFaceUp = true
            if firstCard.emoji == card.emoji {
                cards[index].isMatched = true
                if let firstIndex = cards.firstIndex(where: { $0.id == firstCard.id }) {
                    cards[firstIndex].isMatched = true
                }
                score += 2
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.cards[index].isFaceUp = false
                    if let firstIndex = self.cards.firstIndex(where: { $0.id == firstCard.id }) {
                        self.cards[firstIndex].isFaceUp = false
                    }
                }
                score = max(0, score - 1)
            }
            firstCardChosen = nil
        } else {
            firstCardChosen = cards[index]
            cards[index].isFaceUp = true
        }
        
        checkGameOver()
    }
    
    private func checkGameOver() {
        if cards.allSatisfy({ $0.isMatched }) {
            gameOver = true
        }
    }
}

struct ContentView: View {
    @StateObject var gameView = MemoryGameViewModel()
    @State private var isLandscape: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if isLandscape {
                    HStack {
                        Spacer()
                        createCardGrid(screenSize: geometry.size)
                        Spacer()
                        ControlPanel(gameView: gameView)
                    }
                } else {
                    VStack {
                        Spacer()
                        createCardGrid(screenSize: geometry.size)
                        Spacer()
                        ControlPanel(gameView: gameView)
                    }
                }
            }
            .background(Color.blue.opacity(0.2)).edgesIgnoringSafeArea(.all)
            .onAppear {
                isLandscape = geometry.size.width > geometry.size.height
            }
            .onChange(of: geometry.size) { newSize in
                withAnimation {
                    isLandscape = newSize.width > newSize.height
                }
            }
        }
    }
    
    private func createCardGrid(screenSize: CGSize) -> some View {
        let columns = Array(repeating: GridItem(.adaptive(minimum: isLandscape ? 100 : 80)), count: isLandscape ? 4 : 4)
        
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(gameView.cards) { card in
                CardView(gameView: gameView, card: card)
            }
        }
        .padding()
    }
}

struct CardView: View {
    @ObservedObject var gameView: MemoryGameViewModel
    let card: Card
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            if card.isFaceUp {
                CardFront(emoji: card.emoji)
            } else {
                CardBack()
            }
        }
        .frame(width: 80, height: 120)
        .rotation3DEffect(
            .degrees(card.isFaceUp ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    self.dragOffset = value.translation
                }
                .onEnded { _ in
                    withAnimation {
                        self.dragOffset = .zero
                    }
                }
        )
        .onTapGesture {
            withAnimation {
                gameView.selectCard(card)
            }
        }
    }
}

private struct CardFront: View {
    let emoji: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white)
            .shadow(radius: 2)
            .overlay(
                Text(emoji)
                    .font(.largeTitle)
            )
    }
}

private struct CardBack: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue)
            .shadow(radius: 3)
    }
}

private struct ControlPanel: View {
    @ObservedObject var gameView: MemoryGameViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Score: \(gameView.score)").font(.headline)
                Spacer()
                Text("Moves: \(gameView.moves)").font(.headline)
            }
            .padding()
            
            Button("New Game") {
                withAnimation {
                    gameView.startNewGame()
                }
            }
            .buttonStyle(.borderedProminent)
            
            if gameView.gameOver {
                Text("Game Over").font(.title).foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

