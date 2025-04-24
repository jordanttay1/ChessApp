import Foundation

/// Represents a position on the chessboard using Rank (row) and File (column).
/// Origin (0,0) is A1. Rank increases upwards, File increases to the right.
struct Position: Hashable, Equatable {
    let file: Int // 0='A', 1='B', ..., 7='H'
    let rank: Int // 0='1', 1='2', ..., 7='8'

    /// Checks if the position is within the standard 8x8 board boundaries.
    var isValid: Bool {
        return file >= 0 && file < 8 && rank >= 0 && rank < 8
    }

    /// Initializes a Position from standard algebraic notation (e.g., "e4", "a1", "h8").
    /// Returns nil if the notation is invalid.
    init?(algebraicNotation: String) {
        guard algebraicNotation.count == 2 else { return nil }
        let lowercased = algebraicNotation.lowercased()
        guard let fileChar = lowercased.first, let rankChar = lowercased.last else { return nil }
        guard let fileIndex = fileChar.asciiValue.map({ Int($0) - Int(Character("a").asciiValue!) }),
              let rankIndex = rankChar.wholeNumberValue.map({ $0 - 1 }) else { return nil }

        guard fileIndex >= 0 && fileIndex < 8 && rankIndex >= 0 && rankIndex < 8 else { return nil }

        self.file = fileIndex
        self.rank = rankIndex
    }

    /// Initializes a Position from file and rank indices (0-7).
    init(file: Int, rank: Int) {
        self.file = file
        self.rank = rank
    }

    /// Returns the standard algebraic notation for the position (e.g., "e4").
    var algebraicNotation: String {
        guard isValid else { return "??" } // Should not happen if used correctly
        let fileChar = Character(UnicodeScalar(UInt8(file) + Character("a").asciiValue!))
        let rankChar = Character(UnicodeScalar(UInt8(rank) + Character("1").asciiValue!))
        return String(fileChar) + String(rankChar)
    }
}

/// Represents the state of the chessboard.
struct Board {
    /// An 8x8 array storing the piece at each square, or nil if empty.
    /// `squares[rank][file]` format. Access using `squares[pos.rank][pos.file]`.
    private(set) var squares: [[Piece?]] // Rank major order [rank][file]

    /// Initializes a standard starting chess position.
    init() {
        self.squares = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        setupStartingPosition()
    }

    /// Initializes an empty board.
    init(empty: Bool) {
        self.squares = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        if !empty {
            setupStartingPosition()
        }
    }
    
    /// Initializes board from a custom square layout
    init(squares: [[Piece?]]) {
         guard squares.count == 8 && squares.allSatisfy({ $0.count == 8 }) else {
            // Handle error or default to empty/standard if dimensions are wrong
            print("Error: Invalid dimensions for custom board state. Initializing standard board.")
             self.squares = Array(repeating: Array(repeating: nil, count: 8), count: 8)
            setupStartingPosition()
            return
        }
        self.squares = squares
    }

    /// Retrieves the piece at a given position. Returns nil if the position is invalid or the square is empty.
    subscript(position: Position) -> Piece? {
        get {
            guard position.isValid else { return nil }
            return squares[position.rank][position.file]
        }
        // Private set to ensure mutations happen through controlled methods (like `movePiece`)
        // If direct mutation is needed, make this internal or public with care.
        mutating set {
            guard position.isValid else { return }
            squares[position.rank][position.file] = newValue
        }
    }
    
    /// Overload for direct file/rank access
    subscript(file: Int, rank: Int) -> Piece? {
         get {
             let pos = Position(file: file, rank: rank)
             return self[pos]
        }
         mutating set {
             let pos = Position(file: file, rank: rank)
             self[pos] = newValue
        }
    }

    /// Moves a piece from a starting position to an ending position.
    /// Does not validate the move legality, only performs the state change.
    /// Returns the piece that was captured, if any.
    @discardableResult
    mutating func movePiece(from start: Position, to end: Position) -> Piece? {
        guard start.isValid, end.isValid, let pieceToMove = self[start] else {
             print("Error: Invalid move specified for board update (\(start.algebraicNotation) -> \(end.algebraicNotation)).")
            return nil
        }

        let capturedPiece = self[end]

        self[start] = nil // Clear the starting square
        self[end] = pieceToMove // Place the piece on the ending square

        // TODO: Handle special moves like castling, en passant, promotion here or in GameLogic

        return capturedPiece
    }

    /// Places a piece at a specific position. Useful for setup or special moves like promotion.
    mutating func setPiece(_ piece: Piece?, at position: Position) {
         guard position.isValid else { 
             print("Error: Attempted to set piece at invalid position \(position.algebraicNotation)")
             return 
         }
        self[position] = piece
    }

    /// Sets up the standard initial arrangement of pieces on the board.
    private mutating func setupStartingPosition() {
        // Pawns
        for file in 0..<8 {
            self[Position(file: file, rank: 1)] = Piece(type: .pawn, color: .white)
            self[Position(file: file, rank: 6)] = Piece(type: .pawn, color: .black)
        }

        // Rooks
        self[Position(file: 0, rank: 0)] = Piece(type: .rook, color: .white)
        self[Position(file: 7, rank: 0)] = Piece(type: .rook, color: .white)
        self[Position(file: 0, rank: 7)] = Piece(type: .rook, color: .black)
        self[Position(file: 7, rank: 7)] = Piece(type: .rook, color: .black)

        // Knights
        self[Position(file: 1, rank: 0)] = Piece(type: .knight, color: .white)
        self[Position(file: 6, rank: 0)] = Piece(type: .knight, color: .white)
        self[Position(file: 1, rank: 7)] = Piece(type: .knight, color: .black)
        self[Position(file: 6, rank: 7)] = Piece(type: .knight, color: .black)

        // Bishops
        self[Position(file: 2, rank: 0)] = Piece(type: .bishop, color: .white)
        self[Position(file: 5, rank: 0)] = Piece(type: .bishop, color: .white)
        self[Position(file: 2, rank: 7)] = Piece(type: .bishop, color: .black)
        self[Position(file: 5, rank: 7)] = Piece(type: .bishop, color: .black)

        // Queens
        self[Position(file: 3, rank: 0)] = Piece(type: .queen, color: .white)
        self[Position(file: 3, rank: 7)] = Piece(type: .queen, color: .black)

        // Kings
        self[Position(file: 4, rank: 0)] = Piece(type: .king, color: .white)
        self[Position(file: 4, rank: 7)] = Piece(type: .king, color: .black)
    }
    
    /// Finds the position of the king for a given color.
    /// Returns nil if the king is not found (which shouldn't happen in a valid game state).
    func findKingPosition(for color: PlayerColor) -> Position? {
        for rank in 0..<8 {
            for file in 0..<8 {
                let pos = Position(file: file, rank: rank)
                if let piece = self[pos], piece.type == .king, piece.color == color {
                    return pos
                }
            }
        }
        return nil // King not found
    }
} 