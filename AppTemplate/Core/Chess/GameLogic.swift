import Foundation

/// Represents the current status of the chess game.
enum GameStatus {
    case ongoing
    case checkmate(winner: PlayerColor)
    case stalemate
    // TODO: Add cases for other draw conditions (50-move rule, repetition, insufficient material)
}

/// Manages the state and rules of a chess game.
class GameLogic {
    
    /// The current state of the chessboard.
    private(set) var board: Board
    
    /// The player whose turn it is to move.
    private(set) var currentPlayer: PlayerColor
    
    /// Represents the availability of castling for both players.
    private(set) var castlingRights: CastlingRights
    
    /// The square over which a pawn has just passed, making it vulnerable to en passant capture.
    /// Nil if no en passant capture is possible.
    private(set) var enPassantTarget: Position?
    
    /// The current status of the game (ongoing, checkmate, stalemate).
    private(set) var gameStatus: GameStatus
    
    // TODO: Add properties for move history, halfmove clock (for 50-move rule), fullmove number

    /// Initializes a new game with the standard starting position.
    init() {
        self.board = Board()
        self.currentPlayer = .white
        self.castlingRights = CastlingRights()
        self.enPassantTarget = nil
        self.gameStatus = .ongoing // Start as ongoing
        // Initial status update might be needed if starting from a custom position
        // that could already be checkmate/stalemate, but for standard start, ongoing is correct.
    }
    
    /// Initializes a game from a specific state (e.g., for analysis or loading).
    init(board: Board, currentPlayer: PlayerColor, castlingRights: CastlingRights, enPassantTarget: Position?) {
        self.board = board
        self.currentPlayer = currentPlayer
        self.castlingRights = castlingRights
        self.enPassantTarget = enPassantTarget
        self.gameStatus = .ongoing // Default, should be updated immediately
        // Update status based on the provided state
        updateGameStatus() 
    }
    
    /// Creates a deep copy of the current game state.
    func copy() -> GameLogic {
        return GameLogic(board: self.board, // Structs copy by value
                         currentPlayer: self.currentPlayer, // Enums copy by value
                         castlingRights: self.castlingRights, // Structs copy by value
                         enPassantTarget: self.enPassantTarget // Optional Struct copies by value
        )
    }
    
    // MARK: - Move Generation (Legal)
    
    /// Generates all strictly legal moves for the current player.
    /// Filters pseudo-legal moves by ensuring they do not leave the king in check.
    func generateLegalMoves() -> [Move] {
        let pseudoLegalMoves = generatePseudoLegalMoves()
        var legalMoves: [Move] = []

        let originalPlayer = self.currentPlayer // Player making the move

        for move in pseudoLegalMoves {
            // Create a temporary copy of the game state
            let tempGame = self.copy()
            
            // Apply the move to the temporary state
            // Note: makeMove switches the player internally
            tempGame.makeMove(move)
            
            // Check if the king of the player *who made the move* is in check 
            // after the move was completed. We need to check the board state
            // *after* the move, but from the perspective of the *original* player's king.
            guard let kingPosition = tempGame.board.findKingPosition(for: originalPlayer) else {
                // This case should theoretically not happen if the board starts valid
                // and pseudo-legal moves don't remove the king.
                print("Warning: King not found after move \(move.basicAlgebraicNotation). Move considered illegal.")
                continue 
            }
            
            // Check if the original player's king is attacked by the *now* current player (opponent)
            if !tempGame.isSquareAttacked(by: tempGame.currentPlayer, at: kingPosition) {
                legalMoves.append(move)
            }
        }
        
        return legalMoves
    }
    
    // MARK: - Move Generation (Pseudo-Legal)
    
    /// Generates all pseudo-legal moves for the current player.
    /// Pseudo-legal moves are moves that are valid according to piece movement rules,
    /// but do not account for checks (i.e., moving into check is possible).
    func generatePseudoLegalMoves() -> [Move] {
        var moves: [Move] = []
        let colorToMove = currentPlayer
        
        for rank in 0..<8 {
            for file in 0..<8 {
                let currentPosition = Position(file: file, rank: rank)
                guard let piece = board[currentPosition], piece.color == colorToMove else {
                    continue // Skip empty squares or opponent's pieces
                }
                
                switch piece.type {
                    case .pawn: moves.append(contentsOf: generatePseudoLegalPawnMoves(from: currentPosition))
                    case .knight: moves.append(contentsOf: generatePseudoLegalKnightMoves(from: currentPosition))
                    case .bishop: moves.append(contentsOf: generatePseudoLegalSlidingMoves(from: currentPosition, directions: BishopDirections))
                    case .rook: moves.append(contentsOf: generatePseudoLegalSlidingMoves(from: currentPosition, directions: RookDirections))
                    case .queen: moves.append(contentsOf: generatePseudoLegalSlidingMoves(from: currentPosition, directions: QueenDirections))
                    case .king: moves.append(contentsOf: generatePseudoLegalKingMoves(from: currentPosition))
                }
            }
        }
        // Add castling moves
        moves.append(contentsOf: generatePseudoLegalCastlingMoves())
        
        return moves
    }
    
    // MARK: - Piece-Specific Pseudo-Legal Move Generation Helpers
    
    // Typealias for movement directions (delta file, delta rank)
    typealias Direction = (df: Int, dr: Int)
    let BishopDirections: [Direction] = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
    let RookDirections: [Direction] = [(0, 1), (0, -1), (1, 0), (-1, 0)]
    let QueenDirections: [Direction] = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]
    let KnightMoves: [Direction] = [(1, 2), (1, -2), (-1, 2), (-1, -2), (2, 1), (2, -1), (-2, 1), (-2, -1)]
    let KingMoves: [Direction] = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]

    private func generatePseudoLegalPawnMoves(from start: Position) -> [Move] {
        var moves: [Move] = []
        guard let pawn = board[start], pawn.type == .pawn else { return [] }
        
        let direction = (pawn.color == .white) ? 1 : -1
        let startRank = (pawn.color == .white) ? 1 : 6
        let promotionRank = (pawn.color == .white) ? 7 : 0

        // 1. Single step forward
        let oneStepForward = Position(file: start.file, rank: start.rank + direction)
        if oneStepForward.isValid && board[oneStepForward] == nil {
            // Check for promotion
            if oneStepForward.rank == promotionRank {
                moves.append(contentsOf: createPromotionMoves(from: start, to: oneStepForward))
            } else {
                moves.append(Move(from: start, to: oneStepForward))
            }

            // 2. Double step forward (only if single step was possible and pawn is on starting rank)
            if start.rank == startRank {
                let twoStepsForward = Position(file: start.file, rank: start.rank + 2 * direction)
                if twoStepsForward.isValid && board[twoStepsForward] == nil {
                    moves.append(Move(from: start, to: twoStepsForward))
                }
            }
        }

        // 3. Diagonal captures
        for captureFileOffset in [-1, 1] {
            let captureFile = start.file + captureFileOffset
            let captureRank = start.rank + direction
            let capturePosition = Position(file: captureFile, rank: captureRank)

            if capturePosition.isValid {
                // Regular capture
                if let targetPiece = board[capturePosition], targetPiece.color != pawn.color {
                    if capturePosition.rank == promotionRank {
                        moves.append(contentsOf: createPromotionMoves(from: start, to: capturePosition))
                    } else {
                        moves.append(Move(from: start, to: capturePosition))
                    }
                }
                // En passant capture
                else if capturePosition == enPassantTarget {
                     moves.append(Move(from: start, to: capturePosition, isEnPassant: true))
                }
            }
        }
        
        return moves
    }
    
    /// Helper to create all four promotion moves for a given pawn move.
    private func createPromotionMoves(from start: Position, to end: Position) -> [Move] {
        let promotionTypes: [PieceType] = [.queen, .rook, .bishop, .knight]
        return promotionTypes.map { Move(from: start, to: end, promotion: $0) }
    }
    
    private func generatePseudoLegalKnightMoves(from start: Position) -> [Move] {
        var moves: [Move] = []
        guard let knight = board[start], knight.type == .knight else { return [] }
        
        for moveOffset in KnightMoves {
            let endFile = start.file + moveOffset.df
            let endRank = start.rank + moveOffset.dr
            let endPosition = Position(file: endFile, rank: endRank)
            
            if endPosition.isValid {
                // Can move to an empty square or capture an opponent's piece
                if board[endPosition] == nil || board[endPosition]?.color != knight.color {
                    moves.append(Move(from: start, to: endPosition))
                }
            }
        }
        return moves
    }
    
    /// Generates moves for sliding pieces (Bishop, Rook, Queen).
    private func generatePseudoLegalSlidingMoves(from start: Position, directions: [Direction]) -> [Move] {
        var moves: [Move] = []
        guard let piece = board[start] else { return [] }
        
        for direction in directions {
            var currentFile = start.file + direction.df
            var currentRank = start.rank + direction.dr
            
            while true {
                let endPosition = Position(file: currentFile, rank: currentRank)
                guard endPosition.isValid else { break } // Stop if off board
                
                if let targetPiece = board[endPosition] {
                    // Can capture opponent's piece
                    if targetPiece.color != piece.color {
                        moves.append(Move(from: start, to: endPosition))
                    }
                    break // Stop after hitting any piece (own or opponent)
                } else {
                    // Can move to empty square
                    moves.append(Move(from: start, to: endPosition))
                }
                
                // Continue sliding
                currentFile += direction.df
                currentRank += direction.dr
            }
        }
        return moves
    }
    
    private func generatePseudoLegalKingMoves(from start: Position) -> [Move] {
        var moves: [Move] = []
        guard let king = board[start], king.type == .king else { return [] }
        
        for moveOffset in KingMoves {
            let endFile = start.file + moveOffset.df
            let endRank = start.rank + moveOffset.dr
            let endPosition = Position(file: endFile, rank: endRank)
            
            if endPosition.isValid {
                // Can move to an empty square or capture an opponent's piece
                if board[endPosition] == nil || board[endPosition]?.color != king.color {
                    // TODO: Check if endPosition is attacked by the opponent (needed for legal move generation, but can be deferred or added here)
                    moves.append(Move(from: start, to: endPosition))
                }
            }
        }
        // TODO: Add castling moves (check rights, check path clear, check squares not attacked)
        return moves
    }

    private func generatePseudoLegalCastlingMoves() -> [Move] {
        var moves: [Move] = []
        let color = currentPlayer
        let opponentColor = color.opposite
        let kingRank = (color == .white) ? 0 : 7
        let kingStartPos = Position(file: 4, rank: kingRank)
        
        // Cannot castle if king is in check
        guard !isSquareAttacked(by: opponentColor, at: kingStartPos) else {
            return []
        }
        
        // Kingside Castling (O-O)
        if castlingRights.canCastle(color: color, kingside: true) {
            let pathSquare1 = Position(file: 5, rank: kingRank) // f1/f8
            let pathSquare2 = Position(file: 6, rank: kingRank) // g1/g8
            
            if board[pathSquare1] == nil && board[pathSquare2] == nil {
                 // Check if path squares are attacked
                if !isSquareAttacked(by: opponentColor, at: pathSquare1) && 
                   !isSquareAttacked(by: opponentColor, at: pathSquare2) {
                    moves.append(Move(castleKingsideFor: color))
                }
            }
        }
        
        // Queenside Castling (O-O-O)
        if castlingRights.canCastle(color: color, kingside: false) {
            let pathSquare1 = Position(file: 3, rank: kingRank) // d1/d8
            let pathSquare2 = Position(file: 2, rank: kingRank) // c1/c8
            let rookSquare = Position(file: 1, rank: kingRank) // b1/b8 (must be empty for rook passage)

            if board[pathSquare1] == nil && board[pathSquare2] == nil && board[rookSquare] == nil {
                // Check if path squares king moves through are attacked
                if !isSquareAttacked(by: opponentColor, at: pathSquare1) && 
                   !isSquareAttacked(by: opponentColor, at: pathSquare2) {
                     // Note: Square b1/b8 (rookSquare) doesn't need to be safe for the king
                    moves.append(Move(castleQueensideFor: color))
                }
            }
        }
        
        return moves
    }

    // MARK: - Check Detection

    /// Determines if a given square is attacked by any piece of the specified color.
    func isSquareAttacked(by color: PlayerColor, at position: Position) -> Bool {
        // Check for pawn attacks
        let pawnAttackDirection = (color == .white) ? -1 : 1 // Pawns attack *backwards* relative to their movement
        for fileOffset in [-1, 1] {
            let pawnPos = Position(file: position.file + fileOffset, rank: position.rank + pawnAttackDirection)
            if pawnPos.isValid,
               let piece = board[pawnPos],
               piece.type == .pawn,
               piece.color == color {
                return true
            }
        }

        // Check for knight attacks
        for knightMove in KnightMoves {
            let knightPos = Position(file: position.file + knightMove.df, rank: position.rank + knightMove.dr)
            if knightPos.isValid,
               let piece = board[knightPos],
               piece.type == .knight,
               piece.color == color {
                return true
            }
        }

        // Check for sliding attacks (Rook, Bishop, Queen)
        let slidingDirections = QueenDirections // Check all 8 directions
        for direction in slidingDirections {
            var currentFile = position.file + direction.df
            var currentRank = position.rank + direction.dr
            
            while true {
                let currentPos = Position(file: currentFile, rank: currentRank)
                guard currentPos.isValid else { break } // Off board
                
                if let piece = board[currentPos] {
                    // Found a piece. Is it an attacker of the right type and color?
                    if piece.color == color {
                        let isRook = piece.type == .rook
                        let isBishop = piece.type == .bishop
                        let isQueen = piece.type == .queen
                        let isDiagonal = abs(direction.df) == 1 && abs(direction.dr) == 1
                        let isOrthogonal = direction.df == 0 || direction.dr == 0

                        if (isQueen || (isRook && isOrthogonal) || (isBishop && isDiagonal)) {
                             return true // Found attacker
                        }
                    }
                    // Any piece (own or opponent) blocks further sliding attacks in this direction
                    break
                }
                
                currentFile += direction.df
                currentRank += direction.dr
            }
        }

        // Check for king attacks
        for kingMove in KingMoves {
            let kingPos = Position(file: position.file + kingMove.df, rank: position.rank + kingMove.dr)
            if kingPos.isValid,
               let piece = board[kingPos],
               piece.type == .king,
               piece.color == color {
                return true
            }
        }

        return false // No attacker found
    }
    
    /// Checks if the current player's king is in check.
    func isKingInCheck() -> Bool {
        guard let kingPos = board.findKingPosition(for: currentPlayer) else {
            // This should not happen in a valid game state
            print("Error: Could not find king for \(currentPlayer)")
            return false 
        }
        return isSquareAttacked(by: currentPlayer.opposite, at: kingPos)
    }

    // MARK: - Making Moves

    /// Applies the given move to the game state.
    /// Assumes the move is at least pseudo-legal for the current player.
    /// Updates the board, castling rights, en passant target, and current player.
    func makeMove(_ move: Move) {
        guard let piece = board[move.start] else {
            print("Error: Attempting to make a move from an empty square: \(move.basicAlgebraicNotation)")
            return
        }
        guard piece.color == currentPlayer else {
             print("Error: Attempting to move opponent's piece: \(move.basicAlgebraicNotation)")
             return
        }

        var newBoard = board // Work on a mutable copy
        var newCastlingRights = castlingRights
        var newEnPassantTarget: Position? = nil // Reset by default

        // --- Handle the core move and captures ---
        let capturedPiece = newBoard.movePiece(from: move.start, to: move.end)
        
        // --- Handle Special Moves ---
        if move.isPromotion {
            // Replace the pawn with the promotion piece
            if let promotionType = move.promotionPieceType {
                 newBoard.setPiece(Piece(type: promotionType, color: currentPlayer), at: move.end)
            } else {
                // Should not happen if Move object is constructed correctly
                print("Error: Promotion move lacks promotion piece type: \(move.basicAlgebraicNotation)")
            }
        } else if move.isEnPassant {
            // Remove the captured pawn in an en passant move
            let captureRank = (currentPlayer == .white) ? move.end.rank - 1 : move.end.rank + 1
            let capturedPawnPosition = Position(file: move.end.file, rank: captureRank)
            newBoard.setPiece(nil, at: capturedPawnPosition)
        } else if move.isCastle {
            // Move the corresponding rook
            let rank = (currentPlayer == .white) ? 0 : 7
            if move.isCastleKingside {
                let rookStart = Position(file: 7, rank: rank)
                let rookEnd = Position(file: 5, rank: rank)
                newBoard.movePiece(from: rookStart, to: rookEnd)
            } else { // Queenside
                let rookStart = Position(file: 0, rank: rank)
                let rookEnd = Position(file: 3, rank: rank)
                 newBoard.movePiece(from: rookStart, to: rookEnd)
            }
        }
        
        // --- Update Castling Rights ---
        if piece.type == .king {
            newCastlingRights.kingMoved(color: currentPlayer)
        } else if piece.type == .rook {
            // Check if the rook moved from its starting square
            newCastlingRights.rookMoved(from: move.start)
        }
        // Also consider captured rooks affecting opponent's rights
        if let captured = capturedPiece, captured.type == .rook {
            // If a rook is captured on its starting square, rights are lost
            newCastlingRights.rookMoved(from: move.end) // move.end is where the capture happened
        }
        
        // --- Update En Passant Target ---
        if piece.type == .pawn {
            // If it was a double step, set the en passant target
            let rankDifference = abs(move.end.rank - move.start.rank)
            if rankDifference == 2 {
                let targetRank = (currentPlayer == .white) ? move.start.rank + 1 : move.start.rank - 1
                newEnPassantTarget = Position(file: move.start.file, rank: targetRank)
            }
        }
        
        // --- Commit Changes --- 
        self.board = newBoard
        self.castlingRights = newCastlingRights
        self.enPassantTarget = newEnPassantTarget
        
        // --- Switch Player --- 
        self.currentPlayer = currentPlayer.opposite
        
        // TODO: Update halfmove clock (reset on pawn move or capture, increment otherwise)
        // TODO: Update fullmove number (increment after black moves)
        
        // Update game status
        updateGameStatus()
    }
    
    /// Updates the game status based on the current state of the game.
    private func updateGameStatus() {
        if isKingInCheck() {
            if generateLegalMoves().isEmpty {
                self.gameStatus = .checkmate(winner: currentPlayer.opposite)
            } else {
                self.gameStatus = .ongoing
            }
        } else {
            if generateLegalMoves().isEmpty {
                self.gameStatus = .stalemate
            } else {
                self.gameStatus = .ongoing
            }
        }
    }
}

/// Represents the castling availability for both players.
struct CastlingRights: Equatable {
    var whiteKingside: Bool = true
    var whiteQueenside: Bool = true
    var blackKingside: Bool = true
    var blackQueenside: Bool = true
    
    /// Checks if a specific player can castle on a specific side.
    func canCastle(color: PlayerColor, kingside: Bool) -> Bool {
        if color == .white {
            return kingside ? whiteKingside : whiteQueenside
        } else {
            return kingside ? blackKingside : blackQueenside
        }
    }
    
    /// Updates castling rights when a king moves.
    mutating func kingMoved(color: PlayerColor) {
        if color == .white {
            whiteKingside = false
            whiteQueenside = false
        } else {
            blackKingside = false
            blackQueenside = false
        }
    }
    
    /// Updates castling rights when a rook moves.
    mutating func rookMoved(from position: Position) {
        if position == Position(file: 0, rank: 0) { whiteQueenside = false }
        if position == Position(file: 7, rank: 0) { whiteKingside = false }
        if position == Position(file: 0, rank: 7) { blackQueenside = false }
        if position == Position(file: 7, rank: 7) { blackKingside = false }
    }
} 