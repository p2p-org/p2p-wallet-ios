//
//  SendService+Error.swift
//  p2p_wallet
//
//  Created by Chung Tran on 31/05/2022.
//

import Foundation

extension SendService {
    enum Error: String, Swift.Error, LocalizedError {
        case invalidSourceWallet = "Source wallet is not valid"
        case sendToYourself = "You can not send tokens to yourself"
        case invalidPayingFeeWallet = "Paying fee wallet is not valid"
        case swapPoolsNotFound = "Swap pools not found"
        case unknown = "Unknown error"

        var errorDescription: String? {
            // swiftlint:disable swiftgen_strings
            NSLocalizedString(rawValue, comment: "")
            // swiftlint:enable swiftgen_strings
        }
    }
}
