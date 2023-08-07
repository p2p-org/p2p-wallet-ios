import Foundation

// MARK: - Message

struct SwapAlertLoggerMessage: Codable {
    let tokenA: SwapAlertLoggerMessageTokenA
    let tokenB: SwapAlertLoggerMessageTokenB
    let route, userPubkey, slippage, feeRelayerTransaction: String
    let platform, appVersion, timestamp, blockchainError: String
    let diffRoutesTime: String
    let diffTxTime: String

    enum CodingKeys: String, CodingKey {
        case tokenA = "token_a"
        case tokenB = "token_b"
        case route
        case userPubkey = "user_pubkey"
        case slippage
        case feeRelayerTransaction = "fee_relayer_transaction"
        case platform
        case appVersion = "app_version"
        case timestamp
        case blockchainError = "blockchain_error"
        case diffRoutesTime = "diff_routes_time"
        case diffTxTime = "diff_tx_time"
    }

    init(
        tokenA: SwapAlertLoggerMessageTokenA,
        tokenB: SwapAlertLoggerMessageTokenB,
        route: String,
        userPubkey: String,
        slippage: String,
        feeRelayerTransaction: String,
        platform: String,
        appVersion: String,
        timestamp: String,
        blockchainError: String,
        diffRoutesTime: String,
        diffTxTime: String
    ) {
        self.tokenA = tokenA
        self.tokenB = tokenB
        self.route = route
        self.userPubkey = userPubkey
        self.slippage = slippage
        self.feeRelayerTransaction = feeRelayerTransaction
        self.platform = platform
        self.appVersion = appVersion
        self.timestamp = timestamp
        self.blockchainError = blockchainError
        self.diffRoutesTime = diffRoutesTime
        self.diffTxTime = diffTxTime
    }
}

// MARK: - TokenA

struct SwapAlertLoggerMessageTokenA: Codable {
    let name, mint, sendAmount, balance: String

    enum CodingKeys: String, CodingKey {
        case name, mint
        case sendAmount = "send_amount"
        case balance
    }

    init(name: String, mint: String, sendAmount: String, balance: String) {
        self.name = name
        self.mint = mint
        self.sendAmount = sendAmount
        self.balance = balance
    }
}

// MARK: - TokenB

struct SwapAlertLoggerMessageTokenB: Codable {
    let name, mint, expectedAmount, balance: String

    enum CodingKeys: String, CodingKey {
        case name, mint
        case expectedAmount = "expected_amount"
        case balance
    }

    init(name: String, mint: String, expectedAmount: String, balance: String) {
        self.name = name
        self.mint = mint
        self.expectedAmount = expectedAmount
        self.balance = balance
    }
}
