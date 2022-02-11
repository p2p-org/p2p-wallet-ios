//
// Created by Giang Long Tran on 11.02.2022.
//

import Foundation

struct PayingFeeAccount {
    let address: String
    let mint: String

    static func fromWallet(wallet: Wallet) throws -> PayingFeeAccount {
        guard let address = wallet.pubkey else {throw NSError(domain: "PayingFeeToken", code: 1)}
        return .init(address: address, mint: wallet.mintAddress)
    }
}
