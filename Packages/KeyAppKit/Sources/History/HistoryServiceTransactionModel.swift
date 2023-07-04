import Foundation

public struct HistoryTransactionResponse: Codable {
//    public var id: String
    public var cursor: String?
    public var blockTransactions: [HistoryTransaction]
}

public struct HistoryTransactionResult: Codable {
    let items: [HistoryTransaction]
}

public struct HistoryTransaction: Identifiable, Codable {
    public var id: String { signature }

    public let signature: String
    public let date: Date
    public let status: Status
    public let fees: [Fee]
    private let type: Kind
    public let info: TransactionInfo?
    public let error: Error?

    init(signature: String, date: Date, status: Status, fees: [Fee], type: Kind, info: TransactionInfo, error: Error?) {
        self.signature = signature
        self.date = date
        self.status = status
        self.fees = fees
        self.type = type
        self.info = info
        self.error = error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        signature = try container.decode(String.self, forKey: .signature)

        // Custom decoding date
        let dateStr = try container.decode(String.self, forKey: .date)
        date = HistoryTransaction.dateFormatter.date(from: dateStr) ?? Date()

        status = try container.decode(HistoryTransaction.Status.self, forKey: .status)
        fees = (try? container.decode([Fee].self, forKey: .fees)) ?? []
        error = try container.decodeIfPresent(Error.self, forKey: .error)

        // Make compatible for old version
        guard let type: Kind = try? container.decode(HistoryTransaction.Kind.self, forKey: .type) else {
            self.type = .unknown
            info = nil
            return
        }

        self.type = type

        // Compatible mechanic
        do {
            switch type {
            case .send:
                info = .send(try container.decode(Transfer.self, forKey: .info))
            case .receive:
                info = .receive(try container.decode(Transfer.self, forKey: .info))
            case .swap:
                info = .swap(try container.decode(Swap.self, forKey: .info))
            case .stake:
                info = .stake(try container.decode(Transfer.self, forKey: .info))
            case .unstake:
                info = .unstake(try container.decode(Transfer.self, forKey: .info))
            case .createAccount:
                info = .createAccount(try container.decode(TokenAmount.self, forKey: .info))
            case .closeAccount:
                info = .closeAccount(try container.decode(TokenAmount.self, forKey: .info))
            case .mint:
                info = .mint(try container.decode(TokenAmount.self, forKey: .info))
            case .burn:
                info = .burn(try container.decode(TokenAmount.self, forKey: .info))
            case .wormholeSend:
                info = .wormholeSend(try container.decode(WormholeSend.self, forKey: .info))
            case .wormholeReceive:
                info = .wormholeReceive(try container.decode(WormholeReceive.self, forKey: .info))
            case .tryCreateAccount:
                info = .tryCreateAccount
            case .unknown:
                info = .unknown(try container.decode(TokenAmount.self, forKey: .info))
            }
        } catch {
            info = nil
        }
    }

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        return dateFormatter
    }()
}

public extension HistoryTransaction {
    struct NamedAccount: Codable {
        public var address: String
        public var name: String?
    }

    enum Kind: String, Codable {
        case send
        case receive
        case swap
        case stake = "stake_delegate"
        case unstake
        case createAccount = "create_account"
        case closeAccount = "close_account"
        case burn
        case mint
        case wormholeSend = "wormhole_send"
        case wormholeReceive = "wormhole_receive"
        case tryCreateAccount = "try_create_account"
        case unknown
    }

    enum Status: String, Codable {
        case success
        case failed
    }

    struct Error: Codable {
        public let code: Int
        public let message: String
        public let description: String?
    }

    enum TransactionInfo: Codable {
        case send(Transfer)
        case receive(Transfer)
        case swap(Swap)
        case stake(Transfer)
        case unstake(Transfer)
        case createAccount(TokenAmount)
        case closeAccount(TokenAmount?)
        case burn(TokenAmount)
        case mint(TokenAmount)
        case wormholeSend(WormholeSend)
        case wormholeReceive(WormholeReceive)
        case tryCreateAccount
        case unknown(TokenAmount)
    }

    struct Transfer: Codable {
        public let account: NamedAccount
        public let token: Token
        public let amount: Amount
    }

    struct Swap: Codable {
        public let from: TokenAmount
        public let to: TokenAmount
        public let transitive: [TokenAmount]?
        public let swapPrograms: [NamedAccount]

        enum CodingKeys: String, CodingKey {
            case from
            case to
            case transitive
            case swapPrograms = "swap_programs"
        }
    }

    struct WormholeSend: Codable {
        public let to: NamedAccount

        // Bundle id
        public let bridgeServiceKey: String

        public let tokenAmount: TokenAmount

        enum CodingKeys: String, CodingKey {
            case to
            case bridgeServiceKey = "bridge_service_key"
            case tokenAmount = "token_amount"
        }
    }

    struct WormholeReceive: Codable {
        public let to: NamedAccount?

        // Claim key
        public let bridgeServiceKey: String

        public let tokenAmount: TokenAmount

        enum CodingKeys: String, CodingKey {
            case to
            case bridgeServiceKey = "bridge_service_key"
            case tokenAmount = "token_amount"
        }
    }

    struct Info: Codable {
        public let account: NamedAccount?
        public let tokens: [Token]?
        public let swapPrograms: [NamedAccount]?
        public let voteAccount: VoteAccount?
        public let amount: Amount

        enum CodingKeys: String, CodingKey {
            case account
            case tokens
            case swapPrograms = "swap_programs"
            case voteAccount = "vote_account"
            case amount
        }
    }

    struct Token: Codable {
        public let symbol: String
        public let name: String
        public let mint: String
        public let logoUrl: URL?
        public let usdRate: Double
        public let coingeckoId: String?
        public let decimals: UInt8

        enum CodingKeys: String, CodingKey {
            case symbol
            case name
            case mint
            case logoUrl = "logo_url"
            case usdRate = "usd_rate"
            case coingeckoId = "coingecko_id"
            case decimals
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            symbol = try container.decode(String.self, forKey: .symbol)
            name = try container.decode(String.self, forKey: .name)
            mint = try container.decode(String.self, forKey: .mint)
            logoUrl = try? container.decodeIfPresent(URL.self, forKey: .logoUrl)
            usdRate = Double(try container.decodeIfPresent(String.self, forKey: .usdRate) ?? "") ?? 0.0
            coingeckoId = try container.decodeIfPresent(String.self, forKey: .coingeckoId)
            decimals = try container.decode(UInt8.self, forKey: .decimals)
        }
    }

    struct TokenAmount: Codable {
        public let token: Token
        public let amount: Amount
    }

    struct Amount: Codable {
        public let tokenAmount: Decimal

        public let usdAmount: Decimal?

        @available(*, deprecated, message: "Migrate to decimal")
        public var tokenAmountDouble: Double {
            NSDecimalNumber(decimal: tokenAmount).doubleValue
        }

        @available(*, deprecated, message: "Migrate to decimal")
        public var usdAmountDouble: Double? {
            if let usdAmount {
                return NSDecimalNumber(decimal: usdAmount).doubleValue
            }
            return nil
        }

        enum CodingKeys: String, CodingKey {
            case tokenAmount = "amount"
            case usdAmount = "usd_amount"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let tokenAmountStr = try container.decode(String.self, forKey: .tokenAmount)
            tokenAmount = Decimal(string: tokenAmountStr) ?? 0

            if let usdAmountStr = try container.decodeIfPresent(String.self, forKey: .usdAmount) {
                usdAmount = Decimal(string: usdAmountStr)
            } else {
                usdAmount = nil
            }
        }
    }

    struct Fee: Codable {
        public let type: String
        public let token: Token
        public let amount: Amount
        public let payer: String

        enum CodingKeys: String, CodingKey {
            case type
            case token
            case amount
            case payer
        }
    }
}

public extension HistoryTransaction.Info {
    struct Token: Codable {
        public var balance: Balance
        public var info: Info

        enum CodingKeys: String, CodingKey {
            case balance = "tokens_balance"
            case info = "tokens_info"
        }
    }

    struct VoteAccount: Codable {
        public var name: String?
        public var address: String

        enum CodingKeys: String, CodingKey {
            case name
            case address
        }
    }
}

public extension HistoryTransaction.Info.Token {
    struct Balance: Codable {
        public var before: String
        public var after: String

        enum CodingKeys: String, CodingKey {
            case before = "balance_before"
            case after = "balance_after"
        }
    }

    struct Info: Codable {
        public var swapRole: String?
        public var mint: String
        public var symbol: String?
        public var tokenPrice: String
    }
}
