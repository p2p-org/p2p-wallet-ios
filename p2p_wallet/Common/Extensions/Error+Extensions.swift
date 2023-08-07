import FeeRelayerSwift
import Foundation
import SolanaSwift

extension Error {
    var isNetworkConnectionError: Bool {
        (self as NSError).isNetworkConnectionError
    }

    var readableDescription: String {
        (self as? LocalizedError)?.errorDescription ?? "\(self)"
    }
}

extension SolanaSwift.APIClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidAPIURL:
            return L10n.invalidURL
        case .invalidResponse:
            return L10n.responseError
        case let .responseError(responseError):
            var string = L10n.responseError
            if let description = responseError.message {
                string = description.localized()
            }
            return string
        case .transactionSimulationError:
            return L10n.transactionFailed
        case .couldNotRetrieveAccountInfo:
            return L10n.accountNotFound
        case .blockhashNotFound:
            return L10n.blockhashNotFound
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
