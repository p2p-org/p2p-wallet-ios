//
//  FeeRelayer+Error.swift
//  FeeRelayerSwift
//
//  Created by Chung Tran on 30/07/2021.
//

import Foundation

public protocol FeeRelayerErrorDataType: Decodable {}
extension String: FeeRelayerErrorDataType {}

public enum ErrorType: String {
    case parseHashError = "ParseHashError"
    case parsePubkeyError = "ParsePubkeyError"
    case parseKeypairError = "ParseKeypairError"
    case parseSignatureError = "ParseSignatureError"
    case wrongSignature = "WrongSignature"
    case signerError = "SignerError"
    case clientError = "ClientError"
    case programError = "ProgramError"
    case tooSmallAmount = "TooSmallAmount"
    case notEnoughBalance = "NotEnoughBalance "
    case notEnoughTokenBalance = "NotEnoughTokenBalance"
    case decimalsMismatch = "DecimalsMismatch"
    case tokenAccountNotFound = "TokenAccountNotFound"
    case incorrectAccountOwner = "IncorrectAccountOwner"
    case tokenMintMismatch = "TokenMintMismatch"
    case unsupportedRecipientAddress = "UnsupportedRecipientAddress"
    case feeCalculatorNotFound = "FeeCalculatorNotFound"
    case notEnoughOutAmount = "NotEnoughOutAmount"
    case unknownSwapProgramId = "UnknownSwapProgramId"

    case unknown = "UnknownError"
}

public struct FeeRelayerError: Swift.Error, Decodable, Equatable {
    public let code: Int
    public let message: String
    public let data: ErrorDetail?

    public var clientError: ClientError? {
        guard let data = data,
              data.type == .clientError
        else { return nil }

        // look for message
        if message.contains("connection closed before message completed") {
            return .init(
                programLogs: [],
                type: .connectionClosedBeforeMessageCompleted,
                errorLog: "connection closed before message completed"
            )
        }

        // look for error logs
        else if let string = data.data?.array?.first {
            let regexString = #"\"(?:Program|Transfer:) [^\"]+\""#
            let programLogs = matches(for: regexString, in: string)?
                .map { string in
                    string.replacingOccurrences(of: "\"", with: "")
                }

            let errorPrefixes = [
                "Program failed to complete: ",
                "Program log: Error: ",
                "Transfer: insufficient lamports ", // 19266, need 2039280
            ]
            let errorLog = programLogs?.first(
                where: { log in
                    errorPrefixes.contains(where: { log.starts(with: $0) })
                }
            )

            let type: ClientError.ClientErrorType?

            // execeeded maximum number of instructions
            if errorLog?.contains("exceeded maximum number of instructions allowed") == true {
                type = .maximumNumberOfInstructionsAllowedExceeded
            }

            // insufficient funds
            else if errorLog?.contains("insufficient funds") == true ||
                errorLog?.contains("insufficient lamports") == true
            {
                type = .insufficientFunds
            }

            // given pool token amount results in zero trading tokens
            else if errorLog?.contains("Given pool token amount results in zero trading tokens") == true {
                type = .givenPoolTokenAmountResultsInZeroTradingTokens
            }
            
            // swap instruction exceeds desired slippage limit
            else if errorLog?.contains("Swap instruction exceeds desired slippage limit") == true {
                type = .swapInstructionExceedsDesiredSlippageLimit
            }

            // un parsed error
            else {
                type = nil
            }
            return .init(
                programLogs: programLogs,
                type: type,
                errorLog: errorLog?
                    .replacingOccurrences(of: "Program failed to complete: ", with: "")
                    .replacingOccurrences(of: "Program log: Error: ", with: "")
                    .replacingOccurrences(of: "Transfer: ", with: "")
            )
        }

        // nothing found
        else {
            return nil
        }
    }

    public static var unknown: Self {
        .init(code: -1, message: "Unknown error", data: nil)
    }

    public static var wrongAddress: Self {
        .init(code: -2, message: "Wrong address", data: nil)
    }

    public static var swapPoolsNotFound: Self {
        .init(code: -3, message: "Swap pools not found", data: nil)
    }

    public static var transitTokenMintNotFound: Self {
        .init(code: -4, message: "Transit token mint not found", data: nil)
    }

    public static var invalidAmount: Self {
        .init(code: -5, message: "Invalid amount", data: nil)
    }

    public static var invalidSignature: Self {
        .init(code: -6, message: "Invalid signature", data: nil)
    }

    public static var unsupportedSwap: Self {
        .init(code: -7, message: "Unssuported swap", data: nil)
    }

    public static var relayInfoMissing: Self {
        .init(code: -8, message: "Relay info missing", data: nil)
    }

    public static var invalidFeePayer: Self {
        .init(code: -9, message: "Invalid fee payer", data: nil)
    }

    public static var feePayingTokenMissing: Self {
        .init(code: -10, message: "No token for paying fee is provided", data: nil)
    }

    public static var unauthorized: Self {
        .init(code: -11, message: "Unauthorized", data: nil)
    }

    public static func topUpSuccessButTransactionThrows(logs: [String]?) -> Self {
        .init(code: -12, message: "Topping up is successfull, but the transaction failed", data: .init(type: .clientError, data: .init(array: logs)))
    }
    
    public static var inconsistenceRelayContext: Self {
        .init(code: -14, message: "Inconsistence relay context", data: nil)
    }
    
    public static var missingBlockhash: Self {
        .init(code: -15, message: "Missing recent blockhash", data: nil)
    }
    
    public static var missingRelayFeePayer: Self {
        .init(code: -16, message: "Missing relay fee payer", data: nil)
    }
}

public struct ErrorDetail: Decodable, Equatable {
    public let type: ErrorType?
    public let data: ErrorData?

    init(type: ErrorType?, data: ErrorData?) {
        self.type = type
        self.data = data
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let dict = try values.decode([String: ErrorData].self).first

        let code = dict?.key ?? "Unknown"
        type = ErrorType(rawValue: code) ?? .unknown
        data = dict?.value
    }
}

public struct ErrorData: Decodable, Equatable {
    public let array: [String]?
    public let dict: [String: UInt64]?

    init(array: [String]? = nil, dict: [String: UInt64]? = nil) {
        self.array = array
        self.dict = dict
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        array = try? values.decode([String].self)
        dict = try? values.decode([String: UInt64].self)
    }
}

public struct ClientError {
    public let programLogs: [String]?
    public let type: ClientErrorType?
    public let errorLog: String?

    public enum ClientErrorType: String {
        case insufficientFunds = "Insufficient funds"
        case maximumNumberOfInstructionsAllowedExceeded = "Exceeded maximum number of instructions allowed"
        case connectionClosedBeforeMessageCompleted = "Connection closed before message completed"
        case givenPoolTokenAmountResultsInZeroTradingTokens =
            "Given pool token amount results in zero trading tokens"
        case swapInstructionExceedsDesiredSlippageLimit = "Swap instruction exceeds desired slippage limit"
    }
}

private func matches(for regex: String, in text: String) -> [String]? {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch {
        print("invalid regex: \(error.localizedDescription)")
        return nil
    }
}
