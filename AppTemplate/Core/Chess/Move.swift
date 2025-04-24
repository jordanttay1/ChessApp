import Foundation

/// Represents a chess move from a starting position to an ending position.
struct Move: Equatable, Hashable {
    let start: Position
    let end: Position
    
    /// The type of piece to promote a pawn to. Nil if the move is not a promotion.
    let promotionPieceType: PieceType?
    
    /// Flag indicating if this move is a kingside castle (O-O).
    let isCastleKingside: Bool
    
    /// Flag indicating if this move is a queenside castle (O-O-O).
    let isCastleQueenside: Bool
    
    /// Flag indicating if this move is an en passant capture.
    let isEnPassant: Bool

    /// Convenience initializer for regular moves (no promotion or castling).
    init(from start: Position, to end: Position, promotion: PieceType? = nil, isEnPassant: Bool = false) {
        self.start = start
        self.end = end
        self.promotionPieceType = promotion
        self.isCastleKingside = false
        self.isCastleQueenside = false
        self.isEnPassant = isEnPassant
    }

    /// Initializer specifically for castling moves.
    init(castleKingsideFor color: PlayerColor) {
        let rank = (color == .white) ? 0 : 7
        self.start = Position(file: 4, rank: rank) // King's start
        self.end = Position(file: 6, rank: rank)   // King's end
        self.promotionPieceType = nil
        self.isCastleKingside = true
        self.isCastleQueenside = false
        self.isEnPassant = false
    }

    /// Initializer specifically for castling moves.
    init(castleQueensideFor color: PlayerColor) {
        let rank = (color == .white) ? 0 : 7
        self.start = Position(file: 4, rank: rank) // King's start
        self.end = Position(file: 2, rank: rank)   // King's end
        self.promotionPieceType = nil
        self.isCastleKingside = false
        self.isCastleQueenside = true
        self.isEnPassant = false
    }

    /// Computed property to easily check if the move is any type of castle.
    var isCastle: Bool {
        return isCastleKingside || isCastleQueenside
    }
    
    /// Computed property to easily check if the move is a pawn promotion.
    var isPromotion: Bool {
        return promotionPieceType != nil
    }
    
    /// Generates a basic algebraic notation string (e.g., "e2e4", "e7e8q"). 
    /// Does not include piece identifiers or check/mate symbols, as that requires more game context.
    var basicAlgebraicNotation: String {
        var notation = start.algebraicNotation + end.algebraicNotation
        if let promotion = promotionPieceType {
            notation += promotion.rawValue.lowercased() // Standard promotion notation uses lowercase
        }
        return notation
    }
} 