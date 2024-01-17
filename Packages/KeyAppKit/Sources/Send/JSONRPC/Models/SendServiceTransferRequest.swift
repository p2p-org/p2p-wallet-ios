import Foundation

// MARK: - SendServiceTransferRequest

struct SendServiceTransferRequest: Codable {
    let userWallet: String
    let mint: String?
    let amount, recipient: String
    let options: SendServiceTransferOptions

    enum CodingKeys: String, CodingKey {
        case userWallet = "user_wallet"
        case mint, amount, recipient, options
    }
}

// MARK: - Options

struct SendServiceTransferOptions: Codable {
    let transferMode: SendServiceTransferMode
    let networkFeePayer, taRentPayer: SendServiceTransferFeePayer

    enum CodingKeys: String, CodingKey {
        case transferMode = "transfer_mode"
        case networkFeePayer = "network_fee_payer"
        case taRentPayer = "ta_rent_payer"
    }
}

// MARK: - TransferMode

public enum SendServiceTransferMode: String, Codable {
    case exactIn = "ExactIn"
    case exactOut = "ExactOut"
}

public enum SendServiceTransferFeePayer: Codable {
    case service
    case userSOL
    case userSameToken
    case other(pubkey: String)

    init(string: String) {
        switch string {
        case Self.service.rawValue:
            self = .service
        case Self.userSOL.rawValue:
            self = .userSOL
        case Self.userSameToken.rawValue:
            self = .userSameToken
        default:
            self = .other(pubkey: string)
        }
    }

    var rawValue: String {
        switch self {
        case .service:
            return "Service"
        case .userSOL:
            return "UserSol"
        case .userSameToken:
            return "UserSameToken"
        case let .other(pubkey):
            return pubkey
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = .init(string: string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
