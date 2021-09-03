//
//  SolanaSDK+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import RxSwift
import FeeRelayerSwift

extension SolanaSDK.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return L10n.unauthorized
        case .notFound:
            return L10n.notFound
        case .invalidRequest(let reason):
            var message = L10n.invalidRequest
            if let reason = reason {
                message = reason.localized()
            }
            return message
        case .invalidResponse(let responseError):
            var string = L10n.responseError
            if let description = responseError.message {
                string = description.localized()
            }
            return string
        case .transactionError(let transactionError, _):
            return transactionError.keys.first
        case .socket(let error):
            var string = L10n.socketReturnsAnError + ": "
            if let error = error as? LocalizedError {
                string += error.errorDescription ?? error.localizedDescription
            } else {
                string += error.localizedDescription
            }
            return string
        case .other(let string):
            return string.localized()
        case .unknown:
            return L10n.unknownError
        }
    }
}

extension FeeRelayer.Error: LocalizedError {
    public var errorDescription: String? {
        var string: String
        switch self.type {
        case .parseHashError: string = "Wrong hash format"
        case .parsePubkeyError: string = "Wrong pubkey format"
        case .parseKeypairError: string = "Wrong keypair format"
        case .parseSignatureError: string = "Wrong signature format"
        case .wrongSignature: string = "Wrong signature"
        case .signerError: string = "Signer error"
        case .clientError:
            if let data = data as? String {
                return data.uppercaseFirst.localized()
            }
            string = "Solana RPC client error"
        case .programError: string = "Solana program error"
        case .tooSmallAmount : string = "Amount is too small"
        case .notEnoughBalance : string = "Not enough balance"
        case .notEnoughTokenBalance : string = "Not enough token balance"
        case .decimalsMismatch : string = "Decimals mismatch"
        case .tokenAccountNotFound: string = "Token account not found"
        case .incorrectAccountOwner : string = "Incorrect account's owner"
        case .tokenMintMismatch : string = "Token mint mismatch"
        case .unsupportedRecipientAddress: string = "Unsupported recipient's address"
        case .feeCalculatorNotFound: string = "Fee calculator not found"
        case .notEnoughOutAmount : string = "Not enough output amount"
        case .unknown: string = "Unknown error"
        }
        
        string = string.localized()
        
        if let data = data as? FeeRelayer.FeeRelayerErrorData {
            var details = [String]()
            
            if let expected = data.expected {
                details.append(" \(L10n.expected): \(expected.toString(maximumFractionDigits: 9))")
            }
            if let minimum = data.minimum {
                details.append(" \(L10n.minimum): \(minimum.toString(maximumFractionDigits: 9))")
            }
            if let actual = data.actual {
                details.append(" \(L10n.actual): \(actual.toString(maximumFractionDigits: 9))")
            }
            if let found = data.found {
                details.append(" \(L10n.actual): \(found.toString(maximumFractionDigits: 9))")
            }
            
            if !details.isEmpty {
                string += ":\n\(details.joined(separator: ", ").uppercaseFirst)"
            }
        } else if let data = data as? String {
            #if DEBUG
            string += " \(data)"
            #endif
        }
        return string
    }
}
