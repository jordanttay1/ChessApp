import Foundation

/// Represents the color of a player or piece.
enum PlayerColor: CaseIterable {
    case white
    case black

    /// Returns the opposite color.
    var opposite: PlayerColor {
        return self == .white ? .black : .white
    }
}

/// Represents the type of a chess piece.
enum PieceType: String, CaseIterable {
    case king = "K"
    case queen = "Q"
    case rook = "R"
    case bishop = "B"
    case knight = "N" // N is standard algebraic notation for Knight
    case pawn = "P"
    
    /// (Optional) A simple point value approximation for the piece type.
    var value: Int {
        switch self {
            case .pawn: return 1
            case .knight: return 3
            case .bishop: return 3
            case .rook: return 5
            case .queen: return 9
            case .king: return 0 // King value is often considered infinite or irrelevant in material count
        }
    }
}

/// Represents a single chess piece with a type and color.
struct Piece: Hashable, Equatable {
    let type: PieceType
    let color: PlayerColor

    /// Returns the standard algebraic notation character for the piece type (uppercase for white, lowercase for black).
    var algebraicNotation: String {
        let typeString = type.rawValue
        return color == .white ? typeString.uppercased() : typeString.lowercased()
    }
    
    /// Provides a unique identifier for the piece image asset (e.g., "white_pawn", "black_king").
    /// Assumes asset names follow this convention.
    var assetName: String {
        "\(color)_\(type.rawValue.lowercased())"
    }
    
    /// Returns the name of the SF Symbol corresponding to the piece type and color.
    var sfSymbolName: String {
        let suffix = color == .white ? ".fill" : ""
        switch type {
            case .king:   return "figure.chess.king" + suffix
            case .queen:  return "figure.chess.queen" + suffix
            case .rook:   return "figure.chess.rook" + suffix
            case .bishop: return "figure.chess.bishop" + suffix
            case .knight: return "figure.chess.knight" + suffix
            case .pawn:   return "figure.chess.pawn" + suffix
        }
    }
} 