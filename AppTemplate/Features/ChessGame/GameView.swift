import SwiftUI

/// The main view for displaying the chess game.
struct GameView: View {
    
    // Create and manage the GameViewModel
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Game Status / Player Turn Info
            Text(gameStatusText)
                .font(.headline)
                .padding()

            // Chess Board View
            ChessBoardView(
                board: viewModel.board, // Pass the board state
                selectedSquare: viewModel.selectedSquare, // Pass selection state
                validMoveTargets: viewModel.validMovesForSelectedPiece.map { $0.end }, // Pass valid move targets
                squareTappedAction: { position in // Pass the tap action handler
                    viewModel.squareTapped(at: position)
                }
            )
            .padding(.horizontal) // Add some horizontal padding around the board

            // Action Buttons (Reset, etc.)
            Button("Reset Game") {
                viewModel.resetGame()
            }
            .padding()
            .buttonStyle(.borderedProminent)
            
            Spacer() // Push content to the top
        }
        .navigationTitle("Chess Game") // Example title
        .navigationBarTitleDisplayMode(.inline)
        // TODO: Add more UI elements (captured pieces, move history, coaching hints)
    }
    
    /// Computed property to display the current game status or player turn.
    private var gameStatusText: String {
        switch viewModel.gameStatus {
        case .ongoing:
            return "Turn: \(viewModel.currentPlayer == .white ? "White" : "Black")"
        case .checkmate(let winner):
            return "Checkmate! \(winner == .white ? "White" : "Black") wins."
        case .stalemate:
            return "Stalemate! Draw."
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Embed in NavigationView for title
             GameView()
        }
    }
} 