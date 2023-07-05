// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppKitCore
import SolanaSwift

/// A strategy for parsing close transactions.
public class CloseAccountParseStrategy: TransactionParseStrategy {
    private let tokensRepository: TokenRepository

    init(tokensRepository: TokenRepository) { self.tokensRepository = tokensRepository }

    public func isHandlable(
        with transactionInfo: TransactionInfo
    ) -> Bool {
        let instructions = transactionInfo.transaction.message.instructions
        switch instructions.count {
        case 1: return instructions.first?.parsed?.type == "closeAccount"
        default: return false
        }
    }

    public func parse(
        _ transactionInfo: TransactionInfo,
        config _: Configuration
    ) async throws -> AnyHashable? {
        let instructions = transactionInfo.transaction.message.instructions
        let closedTokenPubkey = instructions.first?.parsed?.info.account
        let preBalances = transactionInfo.meta?.preBalances
        let preTokenBalance = transactionInfo.meta?.preTokenBalances?.first

        var reimbursedAmountLamports: Lamports?

        if (preBalances?.count ?? 0) > 1 {
            reimbursedAmountLamports = preBalances![1]
        }

        let reimbursedAmount = reimbursedAmountLamports?.convertToBalance(decimals: Decimals.SOL)

        let token: TokenMetadata
        if let preTokenBalance {
            token = try await tokensRepository.get(address: preTokenBalance.mint)
                ?? TokenMetadata.unsupported(mint: preTokenBalance.mint, decimals: 1, symbol: "", supply: nil)
        } else {
            token = TokenMetadata.unsupported(mint: "", decimals: 1, symbol: "", supply: nil)
        }

        return CloseAccountInfo(
            reimbursedAmount: reimbursedAmount,
            closedWallet: SolanaAccount(
                pubkey: closedTokenPubkey,
                lamports: 0,
                token: token
            )
        )
    }
}
