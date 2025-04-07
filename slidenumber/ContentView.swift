import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SlidePuzzleViewModel()
    
    var body: some View {
        VStack {
            Text("New Game")
                .font(.system(size:34, weight: .bold, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
                .background(
                    Rectangle()
                        .fill(Color.indigo.opacity(1))
                        .cornerRadius(10)
                )
            Spacer()
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                spacing: 10
            ) {
                ForEach(viewModel.tiles) { tile in
                    TileView(number: tile.number)
                        .onTapGesture {
                            withAnimation {
                                viewModel.moveTile(tile: tile)
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onEnded { value in
                                    let direction = viewModel.detectSwipeDirection(from: value.translation)
                                    withAnimation {
                                        viewModel.moveWithSwipe(tile: tile, direction: direction)
                                    }
                                }
                        )
                }
            }
            .padding()
            .background(
                Rectangle()
                    .fill(Color.indigo.opacity(0.2))
                    .cornerRadius(10)
                    .padding(5)
            ) 
            
            Text("You Won!!!")
                .font(.system(size:28, design: .rounded)) 
                .fontWeight(.bold)
                .foregroundColor(.red.opacity(0.8))
                .padding(.top, 100)
                .opacity(viewModel.isWin ? 1 : 0)
                .animation(.bouncy, value: viewModel.isWin)
         
            Text("Moves: \(viewModel.moveCount)")
                .font(.system(size:28, design: .rounded)) 
                .fontWeight(.bold)
                .foregroundColor(.indigo.opacity(0.9))
                .padding(.top)
            
            HStack {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    Button(action: {
                        withAnimation { 
                            viewModel.setDifficulty(level)
                            viewModel.shuffle()
                        }
                    }) {
                        Text(level.rawValue)
                            .font(.system(size:18, design: .rounded)) 
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(viewModel.difficulty == level ? Color.indigo : Color.indigo.opacity(0.4))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 5)
                }
            }
            .padding(.top, 10)
            
            Button(action: {
                withAnimation { 
                    viewModel.shuffle()
                }
            }) {
                Text("Restart Game")
                    .font(.system(size:22, design: .rounded)) 
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.indigo.opacity(0.4))
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            .opacity(viewModel.isWin ? 1 : 0)
            
            Spacer()
        }
    }
}

struct Tile: Identifiable, Equatable {
    let id: UUID
    let number: Int
    
    static let empty = Tile(id: UUID(), number: 0)
}

struct TileView: View {
    let number: Int
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(number > 0 ? Color.indigo.opacity(0.5) : Color.clear, lineWidth: 2)
                .frame(width: 80, height: 80)
            
            if number != 0 {
                Text("\(number)")
                    .font(.system(size:34, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.indigo.opacity(0.9))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: number)
    }
}

enum SwipeDirection {
    case up, down, left, right, none
}

enum DifficultyLevel: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var moveCount: Int {
        switch self {
        case .easy: return 20
        case .medium: return 50
        case .hard: return 100
        }
    }
}

class SlidePuzzleViewModel: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var moveCount: Int = 0
    @Published var isWin: Bool = false
    @Published var difficulty: DifficultyLevel = .medium
    
    private let gridSize = 4
    private let solvedState = Array(1...15) + [0]
    
    init() {
        shuffle()
    }
    
    func setDifficulty(_ level: DifficultyLevel) {
        difficulty = level
    }
    
    func shuffle() {
        var numbers = solvedState
        tiles = numbers.map { Tile(id: UUID(), number: $0) }
        var emptyIndex = numbers.firstIndex(of: 0)!
        let moveCount = difficulty.moveCount
        for _ in 0..<moveCount {
            let possibleMoves = getAdjacentIndices(for: emptyIndex)
            if let randomMove = possibleMoves.randomElement() {
                numbers.swapAt(emptyIndex, randomMove)
                emptyIndex = randomMove
            }
        }
        tiles = numbers.map { Tile(id: UUID(), number: $0) }
        self.moveCount = 0
        isWin = false
    }

    func moveTile(tile: Tile) {
        guard tile.number != 0,
              let tileIndex = tiles.firstIndex(where: { $0.id == tile.id }),
              let emptyIndex = tiles.firstIndex(where: { $0.number == 0 }),
              isAdjacent(tileIndex, emptyIndex)
        else { return }
        
        tiles.swapAt(tileIndex, emptyIndex)
        moveCount += 1
        
        checkWin()
    }
    
    func moveWithSwipe(tile: Tile, direction: SwipeDirection) {
        guard tile.number != 0,
              let tileIndex = tiles.firstIndex(where: { $0.id == tile.id }),
              let emptyIndex = tiles.firstIndex(where: { $0.number == 0 }) else { return }
        
        let tilePosition = indexToPosition(tileIndex)
        let emptyPosition = indexToPosition(emptyIndex)
        
        var canMove = false
        
        switch direction {
        case .up:    canMove = emptyPosition.row == tilePosition.row - 1 && emptyPosition.column == tilePosition.column
        case .down:  canMove = emptyPosition.row == tilePosition.row + 1 && emptyPosition.column == tilePosition.column
        case .left:  canMove = emptyPosition.column == tilePosition.column - 1 && emptyPosition.row == tilePosition.row
        case .right: canMove = emptyPosition.column == tilePosition.column + 1 && emptyPosition.row == tilePosition.row
        case .none:  return
        }
        
        if canMove {
            tiles.swapAt(tileIndex, emptyIndex)
            moveCount += 1
            checkWin()
        }
    }
    
    func detectSwipeDirection(from translation: CGSize) -> SwipeDirection {
        if abs(translation.width) > abs(translation.height) {
            return translation.width > 0 ? .right : .left
        } else {
            return translation.height > 0 ? .down : .up
        }
    }
    
    private func isAdjacent(_ index1: Int, _ index2: Int) -> Bool {
        let pos1 = indexToPosition(index1)
        let pos2 = indexToPosition(index2)
        
        return abs(pos1.row - pos2.row) + abs(pos1.column - pos2.column) == 1
    }
    
    private func indexToPosition(_ index: Int) -> (row: Int, column: Int) {
        let row = index / gridSize
        let column = index % gridSize
        return (row, column)
    }
    
    private func positionToIndex(row: Int, column: Int) -> Int {
        return row * gridSize + column
    }
    
    private func getAdjacentIndices(for index: Int) -> [Int] {
        let position = indexToPosition(index)
        var adjacentPositions: [(row: Int, column: Int)] = []
        
        if position.row > 0 { adjacentPositions.append((position.row - 1, position.column)) } 
        if position.row < gridSize - 1 { adjacentPositions.append((position.row + 1, position.column)) }
        if position.column > 0 { adjacentPositions.append((position.row, position.column - 1)) }
        if position.column < gridSize - 1 { adjacentPositions.append((position.row, position.column + 1)) } 
        
        return adjacentPositions.map { positionToIndex(row: $0.row, column: $0.column) }
    }
    
    private func checkWin() {
        let currentNumbers = tiles.map { $0.number }
        if currentNumbers == solvedState {
            isWin = true
        }
    }
}

#Preview {
    ContentView()
}