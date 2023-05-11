// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let swapErrorInfo = try? JSONDecoder().decode(SwapErrorInfo.self, from: jsonData)

import Foundation

// MARK: - SwapErrorInfo
public struct SwapErrorDetail: Codable {
    public let title: String
    public let message: Message
    
    enum CodingKeys: CodingKey {
        case title
        case message
    }
    
    public init(title: String, message: Message) {
        self.title = title
        self.message = message
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.title, forKey: .title)
        
        // encode message to type String
        let data = try JSONEncoder().encode(message)
        let message = String(data: data, encoding: .utf8)
        try container.encode(message, forKey: .message)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        
        // message is a String
        let messageString = try container.decode(String.self, forKey: .message)
        let data = messageString.data(using: .utf8) ?? Data()
        self.message = try JSONDecoder().decode(Message.self, from: data)
    }
}

// MARK: - Message
public struct Message: Codable {
    public let tokenA: TokenA
    public let tokenB: TokenB
    public let route, userPubkey, slippage, feeRelayerTransaction: String
    public let platform, appVersion, timestamp, blockchainError: String
    
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
    }
    
    public init(tokenA: TokenA, tokenB: TokenB, route: String, userPubkey: String, slippage: String, feeRelayerTransaction: String, platform: String, appVersion: String, timestamp: String, blockchainError: String) {
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
    }
}

// MARK: - TokenA
public struct TokenA: Codable {
    public let name, mint, sendAmount: String
    
    enum CodingKeys: String, CodingKey {
        case name, mint
        case sendAmount = "send_amount"
    }
    
    public init(name: String, mint: String, sendAmount: String) {
        self.name = name
        self.mint = mint
        self.sendAmount = sendAmount
    }
}

// MARK: - TokenB
public struct TokenB: Codable {
    public let name, mint, expectedAmount: String
    
    enum CodingKeys: String, CodingKey {
        case name, mint
        case expectedAmount = "expected_amount"
    }
    
    public init(name: String, mint: String, expectedAmount: String) {
        self.name = name
        self.mint = mint
        self.expectedAmount = expectedAmount
    }
}
