//
//  WormholeSendTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Send
import SolanaSwift
import Wormhole

struct WormholeSendTransaction: RawTransactionType {
    let account: SolanaAccountsService.Account

    let recipient: String

    let amount: CryptoAmount

    var currencyAmount: CurrencyAmount {
        guard let price = account.price else { return .zero }
        return amount.unsafeToFiatAmount(price: price)
    }

    let fees: SendFees

    var mainDescription: String = "Wormhole send"

    var payingFeeWallet: Wallet? = nil

    var feeAmount: FeeAmount = .zero

    func createRequest() async throws -> String {
        UUID().uuidString
    }
}
