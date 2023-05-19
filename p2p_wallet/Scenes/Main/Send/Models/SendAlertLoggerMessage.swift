// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sendAlertLoggerMessage = try? JSONDecoder().decode(SendAlertLoggerMessage.self, from: jsonData)

import Foundation

// MARK: - SendAlertLoggerMessage

struct SendAlertLoggerMessage: Codable {
    let tokenToSend: SendAlertLoggerTokenToSend
    let fees: SendAlertLoggerFees
    let relayAccountState: SendAlertLoggerRelayAccountState?
    let userPubkey, recipientPubkey: String
    let recipientName: String?
    let platform, appVersion, timestamp: String
    let simulationError, feeRelayerError, blockchainError: String?
    
    enum CodingKeys: String, CodingKey {
        case tokenToSend = "token_to_send"
        case fees
        case relayAccountState = "relay_account_state"
        case userPubkey = "user_pubkey"
        case recipientPubkey = "recipient_pubkey"
        case recipientName = "recipient_name"
        case platform
        case appVersion = "app_version"
        case timestamp
        case simulationError = "simulation_error"
        case feeRelayerError = "fee_relayer_error"
        case blockchainError = "blockchain_error"
    }
}

// MARK: - SendAlertLoggerFees

struct SendAlertLoggerFees: Codable {
    let transactionFeeAmount: String
    let accountCreationFee: SendAlertLoggerAccountCreationFee
    
    enum CodingKeys: String, CodingKey {
        case transactionFeeAmount = "transaction_fee_amount"
        case accountCreationFee = "account_creation_fee"
    }
}

// MARK: - SendAlertLoggerAccountCreationFee

struct SendAlertLoggerAccountCreationFee: Codable {
    let paymentToken: SendAlertLoggerPaymentToken
    let amount: String
    
    enum CodingKeys: String, CodingKey {
        case paymentToken = "payment_token"
        case amount
    }
}

// MARK: - SendAlertLoggerPaymentToken

struct SendAlertLoggerPaymentToken: Codable {
    let name, mint: String
}

// MARK: - SendAlertLoggerRelayAccountState

struct SendAlertLoggerRelayAccountState: Codable {
    let created: Bool
    let balance: String
}

// MARK: - SendAlertLoggerTokenToSend

struct SendAlertLoggerTokenToSend: Codable {
    let name, mint, sendAmount, currency: String
    
    enum CodingKeys: String, CodingKey {
        case name, mint
        case sendAmount = "send_amount"
        case currency
    }
}
