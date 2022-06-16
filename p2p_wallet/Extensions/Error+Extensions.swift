//
//  Error+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import FeeRelayerSwift
import Foundation
import RxSwift
import SolanaSwift

extension SolanaError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return L10n.unauthorized
        case .notFound:
            return L10n.notFound
        case let .invalidRequest(reason):
            var message = L10n.invalidRequest
            if let reason = reason {
                message = reason.localized()
            }
            return message
        case let .invalidResponse(responseError):
            var string = L10n.responseError
            if let description = responseError.message {
                string = description.localized()
            }
            return string
        case let .transactionError(transactionError, _):
            return transactionError.snakeCaseEncoded
        // TODO: Check
        // return transactionError.keys.first
        case let .socket(error):
            var string = L10n.socketReturnsAnError + ": "
            if let error = error as? LocalizedError {
                string += error.errorDescription ?? error.localizedDescription
            } else {
                string += error.localizedDescription
            }
            return string
        case let .other(string):
            return string.localized()
        case .unknown:
            return L10n.unknownError
        case .assertionFailed:
            // TODO: pick correct name
            return L10n.error
        default:
            return L10n.error
        }
    }
}

extension FeeRelayerError: LocalizedError {
    public var errorDescription: String? {
        var string: String
        switch data?.type {
        case .parseHashError: string = "Wrong hash format"
        case .parsePubkeyError: string = "Wrong pubkey format"
        case .parseKeypairError: string = "Wrong keypair format"
        case .parseSignatureError: string = "Wrong signature format"
        case .wrongSignature: string = "Wrong signature"
        case .signerError: string = "Signer error"
        case .clientError:
            if let error = clientError, let type = error.type {
                string = type.rawValue
            } else {
                string = clientError?.errorLog ?? message
            }
        case .programError: string = "Solana program error"
        case .tooSmallAmount: string = "Amount is too small"
        case .notEnoughBalance: string = "Not enough balance"
        case .notEnoughTokenBalance: string = "Not enough token balance"
        case .decimalsMismatch: string = "Decimals mismatch"
        case .tokenAccountNotFound: string = "Token account not found"
        case .incorrectAccountOwner: string = "Incorrect account's owner"
        case .tokenMintMismatch: string = "Token mint mismatch"
        case .unsupportedRecipientAddress: string = "Unsupported recipient's address"
        case .feeCalculatorNotFound: string = "Fee calculator not found"
        case .notEnoughOutAmount: string = "Not enough output amount"
        case .unknown: string = "Unknown error"
        default: string = "Unknown error"
        }

        let additionalMessage = message.replacingOccurrences(of: "\(string): ", with: "")
        string = string.localized()
        #if DEBUG
            if data?.type != .clientError {
                string += ": \(additionalMessage)"
                var details = [String]()
                if let array = data?.data?.array {
                    details += array
                }
                if let dictionary = data?.data?.dict {
                    details += dictionary.map { "\($0.key.localized()): \($0.value)" }
                }
                if !details.isEmpty {
                    string += ": \(details.joined(separator: ", ").uppercaseFirst)"
                }
            }
        #endif
        return string
    }
}
