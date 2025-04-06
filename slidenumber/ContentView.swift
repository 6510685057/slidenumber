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
                                viewModel.move(tile: tile)
                            }
                        }
                }
            }
            .padding()
            .background(
                Rectangle()
                    .fill(Color.indigo.opacity(0.2))
                    .cornerRadius(10)
                    .padding(5)) 
            
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
            Button(action: {withAnimation
                { viewModel.shuffle()}}) {
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

class SlidePuzzleViewModel: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var moveCount: Int = 0
    @Published var isWin: Bool = false
    
    private let size = 4
    
    init() {
        shuffle()
    }
    
    func shuffle() {
        var numbers = Array(1...15) + [0]
        repeat {
            numbers.shuffle()
        } while !isSolvable(numbers)
        
        tiles = numbers.map { Tile(id: UUID(), number: $0) }
        moveCount = 0
        isWin = false
        
    }
    
    func move(tile: Tile) {
        guard tile.number != 0,
              let tileIndex = tiles.firstIndex(where: { $0.id == tile.id }),
              let emptyIndex = tiles.firstIndex(where: { $0.number == 0 }),
              isAdjacent(tileIndex, emptyIndex)
        else { return }
        
        tiles.swapAt(tileIndex, emptyIndex)
        moveCount += 1
        
        if tiles.map({ $0.number }) == Array(1...15) + [0] {
            isWin = true
            /*
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.shuffle()
            }*/
        }
    }
    
    private func isAdjacent(_ i1: Int, _ i2: Int) -> Bool {
        let row1 = i1 / size
        let col1 = i1 % size
        let row2 = i2 / size
        let col2 = i2 % size
        return abs(row1 - row2) + abs(col1 - col2) == 1
    }
    
    private func isSolvable(_ numbers: [Int]) -> Bool {
        let flat = numbers.filter { $0 != 0 }
        var inversions = 0
        for i in 0..<flat.count {
            for j in i + 1..<flat.count {
                if flat[i] > flat[j] { inversions += 1 }
            }
        }
        
        if let emptyIndex = numbers.firstIndex(of: 0) {
            let emptyRowFromBottom = size - (emptyIndex / size)
            return (inversions % 2 == 0) == (emptyRowFromBottom % 2 != 0)
        }
        
        return false
    }
}

#Preview {
    ContentView()
}