import SwiftUI
import Combine // For ObservableObject

/// ViewModel responsible for managing the game state and interactions for the GameView.
@MainActor // Ensure UI updates are on the main thread
class GameViewModel: ObservableObject {
    
    // The core game logic engine
    @Published private(set) var gameLogic: GameLogic
    
    // Published properties for the UI to observe
    @Published private(set) var board: Board // Publish the board state directly
    @Published private(set) var currentPlayer: PlayerColor
    @Published private(set) var gameStatus: GameStatus
    @Published private(set) var selectedSquare: Position? = nil
    @Published private(set) var validMovesForSelectedPiece: [Move] = []
    @Published private(set) var lastMove: Move? = nil
    @Published private(set) var kingInCheckPosition: Position? = nil
    
    // TODO: Add properties for coaching hints, AI thinking status, etc.

    init() {
        let initialGameLogic = GameLogic()
        self.gameLogic = initialGameLogic
        self.board = initialGameLogic.board
        self.currentPlayer = initialGameLogic.currentPlayer
        self.gameStatus = initialGameLogic.gameStatus
        updateCheckStatus() // Check initial state
    }
    
    /// Handles user interaction when a square is tapped on the board.
    func squareTapped(at position: Position) {
        print("Tapped square: \(position.algebraicNotation)") // Debugging
        
        if let selected = selectedSquare {
            // Square already selected, try to make a move
            let potentialMove = validMovesForSelectedPiece.first { $0.start == selected && $0.end == position }
            
            if let move = potentialMove {
                print("Attempting move: \(move.basicAlgebraicNotation)") // Debugging
                performMove(move)
            } else {
                 // Tapped a different square, maybe select it if it's the current player's piece
                 if let piece = board[position], piece.color == currentPlayer {
                     selectPiece(at: position)
                 } else {
                     // Invalid move target or empty square, deselect
                     deselectPiece()
                 }
            }
        } else {
            // No square selected, try to select the tapped piece
            if let piece = board[position], piece.color == currentPlayer {
                selectPiece(at: position)
            }
            // If tapping an empty square or opponent piece, do nothing
        }
    }
    
    /// Selects a piece at the given position and calculates its valid moves.
    private func selectPiece(at position: Position) {
        selectedSquare = position
        // Generate legal moves only for the selected piece
        validMovesForSelectedPiece = gameLogic.generateLegalMoves().filter { $0.start == position }
        print("Selected \(board[position]?.type.rawValue ?? "??") at \(position.algebraicNotation). Valid moves: \(validMovesForSelectedPiece.map { $0.basicAlgebraicNotation })")
    }
    
    /// Deselects the currently selected piece.
    private func deselectPiece() {
        selectedSquare = nil
        validMovesForSelectedPiece = []
        print("Deselected piece")
    }
    
    /// Performs the given move, updates the game state, and handles AI turn if necessary.
    private func performMove(_ move: Move) {
        gameLogic.makeMove(move) // Apply the move to the core logic
        
        // Update published properties
        self.board = gameLogic.board
        self.currentPlayer = gameLogic.currentPlayer
        self.gameStatus = gameLogic.gameStatus
        self.lastMove = move // Store the last move made
        updateCheckStatus() // Update check status AFTER the move
        
        // Clear selection state
        deselectPiece()
        
        print("Move made: \(move.basicAlgebraicNotation). New status: \(gameStatus). Current player: \(currentPlayer). King check pos: \(kingInCheckPosition?.algebraicNotation ?? "none")")
        
        // TODO: Trigger AI move if it's AI's turn
        // TODO: Handle promotion selection UI if move.isPromotion
        // TODO: Check game status (checkmate/stalemate) and show appropriate UI
    }
    
    /// Updates the kingInCheckPosition based on the current game state.
    private func updateCheckStatus() {
        if gameLogic.isKingInCheck() {
            self.kingInCheckPosition = gameLogic.board.findKingPosition(for: gameLogic.currentPlayer)
        } else {
            self.kingInCheckPosition = nil
        }
    }
    
    /// Resets the game to the initial state.
    func resetGame() {
         let newGame = GameLogic()
         self.gameLogic = newGame
         self.board = newGame.board
         self.currentPlayer = newGame.currentPlayer
         self.gameStatus = newGame.gameStatus
         self.lastMove = nil // Clear last move
         updateCheckStatus() // Check initial state
         deselectPiece()
         print("Game Reset")
    }
} 