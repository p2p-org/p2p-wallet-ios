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

        self.signature = try container.decode(String.self, forKey: .signature)

        // Custom decoding date
        let dateStr = try container.decode(String.self, forKey: .date)
        self.date = HistoryTransaction.dateFormatter.date(from: dateStr) ?? Date()

        self.status = try container.decode(HistoryTransaction.Status.self, forKey: .status)
        self.fees = (try? container.decode([Fee].self, forKey: .fees)) ?? []
        self.error = try container.decodeIfPresent(Error.self, forKey: .error)

        // Make compatible for old version
        guard let type: Kind = try? container.decode(HistoryTransaction.Kind.self, forKey: .type) else {
            self.type = .unknown
            self.info = nil
            return
        }

        self.type = type

        // Compatible mechanic
        do {
            switch type {
            case .send:
                self.info = .send(try container.decode(Transfer.self, forKey: .info))
            case .receive:
                self.info = .receive(try container.decode(Transfer.self, forKey: .info))
            case .swap:
                self.info = .swap(try container.decode(Swap.self, forKey: .info))
            case .stake:
                self.info = .stake(try container.decode(Transfer.self, forKey: .info))
            case .unstake:
                self.info = .unstake(try container.decode(Transfer.self, forKey: .info))
            case .createAccount:
                self.info = .createAccount(try container.decode(TokenAmount.self, forKey: .info))
            case .closeAccount:
                self.info = .closeAccount(try container.decode(TokenAmount.self, forKey: .info))
            case .mint:
                self.info = .mint(try container.decode(TokenAmount.self, forKey: .info))
            case .burn:
                self.info = .burn(try container.decode(TokenAmount.self, forKey: .info))
            case .unknown:
                self.info = .unknown(try container.decode(TokenAmount.self, forKey: .info))
            }
        } catch {
            self.info = nil
        }
    }

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        return dateFormatter
    }()
}

public extension HistoryTransaction {
    struct Account: Codable {
        public var address: String
        public var username: String?
    }

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
        case unknown(TokenAmount)
    }

    struct Transfer: Codable {
        public let account: Account
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

    struct Info: Codable {
        public let account: Account?
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
            self.symbol = try container.decode(String.self, forKey: .symbol)
            self.name = try container.decode(String.self, forKey: .name)
            self.mint = try container.decode(String.self, forKey: .mint)
            self.logoUrl = try? container.decodeIfPresent(URL.self, forKey: .logoUrl)
            self.usdRate = Double(try container.decodeIfPresent(String.self, forKey: .usdRate) ?? "") ?? 0.0
            self.coingeckoId = try container.decodeIfPresent(String.self, forKey: .coingeckoId)
            self.decimals = try container.decode(UInt8.self, forKey: .decimals)
        }
    }

    struct TokenAmount: Codable {
        public let token: Token
        public let amount: Amount
    }

    struct Amount: Codable {
        public let tokenAmount: Double
        public let usdAmount: Double

        enum CodingKeys: String, CodingKey {
            case tokenAmount = "amount"
            case usdAmount = "usd_amount"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.tokenAmount = Double(try container.decode(String.self, forKey: .tokenAmount)) ?? 0.0
            self.usdAmount = Double(try container.decodeIfPresent(String.self, forKey: .usdAmount) ?? "") ?? 0.0
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
