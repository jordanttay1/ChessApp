import SwiftUI

/// A View that renders the chessboard and handles user interactions on the squares.
struct ChessBoardView: View {
    
    // MARK: - Properties
    let board: Board
    let selectedSquare: Position?
    let validMoveTargets: [Position] // Target squares for the selected piece
    let squareTappedAction: (Position) -> Void // Callback when a square is tapped
    
    // TODO: Add properties for last move highlight, check highlight
    
    // MARK: - Style Constants (from StyleGuide.md)
    private let lightSquareColor = Color(hex: "#E1E1E1")
    private let darkSquareColor = Color(hex: "#6D8A96")
    private let selectionColor = Color(red: 90/255, green: 200/255, blue: 250/255, opacity: 0.5)
    private let validMoveColor = Color(red: 10/255, green: 122/255, blue: 255/255, opacity: 0.3)
    // private let checkHighlightColor = Color(red: 255/255, green: 59/255, blue: 48/255, opacity: 0.4) // For later
    // private let lastMoveHighlightColor = Color.yellow.opacity(0.2) // Placeholder for later
    
    // MARK: - Body
    var body: some View {
        // Determine orientation later if needed
        let boardIsFlipped = false // Assuming White is at the bottom for now
        
        GeometryReader { geometry in
            let squareSize = geometry.size.width / 8.0
            
            ZStack {
                // Draw board squares
                ForEach(0..<8) { rank in
                    ForEach(0..<8) { file in
                        let position = Position(file: file, rank: rank)
                        // Adjust for potential board flipping (not implemented fully yet)
                        let displayRank = boardIsFlipped ? (7 - rank) : rank
                        let displayFile = boardIsFlipped ? (7 - file) : file
                        let correctedPosition = Position(file: displayFile, rank: displayRank)
                        
                        let squareX = CGFloat(file) * squareSize + squareSize / 2
                        let squareY = geometry.size.height - (CGFloat(rank) * squareSize + squareSize / 2)
                        
                        // Base Square
                        Rectangle()
                            .fill(squareColor(at: correctedPosition))
                            .frame(width: squareSize, height: squareSize)
                            .position(x: squareX, y: squareY)
                            .onTapGesture {
                                squareTappedAction(correctedPosition)
                            }
                        
                        // Selection Highlight
                        if correctedPosition == selectedSquare {
                            Rectangle()
                                .fill(selectionColor)
                                .frame(width: squareSize, height: squareSize)
                                .position(x: squareX, y: squareY)
                                .allowsHitTesting(false) // Pass taps through
                        }
                        
                        // Valid Move Indicator
                        if validMoveTargets.contains(correctedPosition) {
                             // Simple dot indicator
                             Circle()
                                 .fill(validMoveColor)
                                 .frame(width: squareSize * 0.3, height: squareSize * 0.3)
                                 .position(x: squareX, y: squareY)
                                 .allowsHitTesting(false) // Pass taps through
                        }
                        
                        // Draw pieces using SF Symbols
                        if let piece = board[correctedPosition] {
                             Image(systemName: piece.sfSymbolName)
                                 .resizable()
                                 .scaledToFit()
                                 // .foregroundColor(piece.color == .white ? .primary : .secondary) // Use semantic colors or define in StyleGuide
                                 .foregroundColor(piece.color == .white ? .black : .white) // Force high contrast
                                 .frame(width: squareSize * 0.7, height: squareSize * 0.7) // Adjust size as needed
                                 .position(x: squareX, y: squareY)
                                  .allowsHitTesting(false) // Don't let text block tap gesture
                        }
                    }
                }
            }
            .aspectRatio(1.0, contentMode: .fit) // Ensure board is square
        }
    }
    
    /// Determines the background color for a square based on its position.
    private func squareColor(at position: Position) -> Color {
        let isLightSquare = (position.file + position.rank) % 2 != 0
        return isLightSquare ? lightSquareColor : darkSquareColor
    }
}

// Helper extension for initializing Color from Hex string
// (Place this outside the struct, e.g., at the bottom of the file or in a separate utility file)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Preview Provider (Optional, but helpful)
struct ChessBoardView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample board state for preview
        let sampleGame = GameLogic()
        let sampleBoard = sampleGame.board
        let validTargets = sampleGame.generateLegalMoves()
            .filter { $0.start == Position(file: 4, rank: 1) } // Example: moves for e2 pawn
            .map { $0.end }
        
        ChessBoardView(board: sampleBoard, 
                       selectedSquare: Position(file: 4, rank: 1), // Example: e2 selected
                       validMoveTargets: validTargets,
                       squareTappedAction: { pos in print("Preview tapped: \(pos.algebraicNotation)") })
            .frame(width: 300, height: 300)
    }
} 