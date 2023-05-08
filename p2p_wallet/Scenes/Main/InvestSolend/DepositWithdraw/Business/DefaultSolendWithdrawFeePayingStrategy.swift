// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import Resolver
import SolanaSwift
import Solend
import KeyAppBusiness
import KeyAppKitCore

class DefaultSolendDepositFeePayingStrategy: SolendFeePayingStrategy {
    let orca: OrcaSwap
    let actionService: SolendActionService
    let solanaAccountsService: SolanaAccountsService

    init(orca: OrcaSwap, actionService: SolendActionService, solanaAccountsService: SolanaAccountsService) {
        self.orca = orca
        self.actionService = actionService
        self.solanaAccountsService = solanaAccountsService
    }

    func calculate(amount: Lamports, symbol: String, mintAddress: String) async throws -> SolendFeePaying {
        // Fee in native token
        let feeInNativeToken = try await actionService.depositFee(amount: amount, symbol: symbol)

        // Fee in same requested spl token
        let feeCalculator: RelayFeeCalculator = DefaultRelayFeeCalculator()
        try await orca.load()
        let feeInToken = try await feeCalculator.calculateFeeInPayingToken(
            orcaSwap: orca,
            feeInSOL: feeInNativeToken,
            payingFeeTokenMint: try PublicKey(string: mintAddress)
        )

        guard let nativeAccount = solanaAccountsService.loadedAccounts.first(where: {$0.isNativeSOL}) else {
            throw SolendFeePayingStrategyError.invalidNativeWallet
        }

        let nativeTokenStrategy: SolendFeePaying = .init(
            symbol: nativeAccount.token.symbol,
            decimals: nativeAccount.token.decimals,
            fee: feeInNativeToken,
            feePayer: TokenAccount(
                address: try PublicKey(string: nativeAccount.pubkey),
                mint: try PublicKey(string: nativeAccount.mintAddress)
            )
        )

        guard
            let userSplAccount: SolanaAccount = solanaAccountsService.loadedAccounts.first(where: { $0.mintAddress == mintAddress }),
            let feeInToken = feeInToken
        else {
            return nativeTokenStrategy
        }

        if (amount + feeInToken.total) <= (userSplAccount.lamports ?? 0) {
            return .init(
                symbol: symbol,
                decimals: userSplAccount.token.decimals,
                fee: feeInToken,
                feePayer: TokenAccount(
                    address: try PublicKey(string: userSplAccount.pubkey),
                    mint: try PublicKey(string: userSplAccount.mintAddress)
                )
            )
        } else {
            return nativeTokenStrategy
        }
    }
}
