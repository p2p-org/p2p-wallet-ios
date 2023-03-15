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
import Wormhole

struct WormholeClaimTransaction: RawTransactionType {
    /// Wormhole service
    let wormholeService: WormholeService

    /// Ethereum token
    let token: EthereumToken

    /// Amount in crypto
    let amountInCrypto: CryptoAmount

    /// Amount in fiat
    let amountInFiat: CurrencyAmount?

    /// Wormhole bundle
    let bundle: WormholeBundle

    var mainDescription: String = "Claim"

    var networkFees: (total: SolanaSwift.Lamports, token: SolanaSwift.Token)? = nil

    var payingFeeWallet: SolanaSwift.Wallet? = nil

    func createRequest() async throws -> String {
        try await wormholeService.sendBundle(bundle: bundle)
        return UUID().uuidString
    }
}
