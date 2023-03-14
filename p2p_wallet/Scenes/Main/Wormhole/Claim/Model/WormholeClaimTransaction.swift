//
//  Wormhole.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift

struct WormholeClaimTransaction: RawTransactionType {
    let token: EthereumToken

    let amountInCrypto: CryptoAmount

    let amountInFiat: CurrencyAmount?

    var mainDescription: String = "Claim"

    var networkFees: (total: SolanaSwift.Lamports, token: SolanaSwift.Token)? = nil

    var payingFeeWallet: SolanaSwift.Wallet? = nil

    func createRequest() async throws -> String {
        try await Task.sleep(nanoseconds: 3_000_000_000)

        return UUID().uuidString
    }
}
