//
// Created by Giang Long Tran on 01.02.2022.
//

import Foundation

// MARK: - Helpers

extension OrcaSwapV2.ViewModel {
    /// Verify error in current context IN ORDER
    /// - Returns: String or nil if no error
    func verify() -> OrcaSwapV2.VerificationError? {
        // loading state
        if loadingState != .loaded {
            return .swappingIsNotAvailable
        }

        // source wallet
        guard let sourceWallet = sourceWallet else {
            return .sourceWalletIsEmpty
        }

        // destination wallet
        guard let destinationWallet = destinationWallet else {
            return .destinationWalletIsEmpty
        }

        // prevent swap the same token
        if sourceWallet.token.address == destinationWallet.token.address {
            return .canNotSwapToItSelf
        }

        // pools pairs
        if tradablePoolsPairsSubject.state != .loaded {
            return .tradablePoolsPairsNotLoaded
        }

        if tradablePoolsPairsSubject.value == nil || tradablePoolsPairsSubject.value?.isEmpty == true {
            return .tradingPairNotSupported
        }

        // inputAmount
        guard let inputAmount = inputAmount else {
            return .inputAmountIsEmpty
        }

        if inputAmount.rounded(decimals: sourceWallet.token.decimals) <= 0 {
            return .inputAmountIsNotValid
        }

        if inputAmount.rounded(decimals: sourceWallet.token.decimals) > availableAmount?
            .rounded(decimals: sourceWallet.token.decimals)
        {
            return .insufficientFunds
        }

        // estimated amount
        guard let estimatedAmount = estimatedAmount else {
            return .estimatedAmountIsNotValid
        }

        if estimatedAmount.rounded(decimals: destinationWallet.token.decimals) <= 0 {
            return .estimatedAmountIsNotValid
        }

        // best pools pairs
        if bestPoolsPair == nil {
            return .bestPoolsPairsIsEmpty
        }

        // fees
        if feesSubject.state.isError {
            return .couldNotCalculatingFees
        }

        guard feesSubject.state == .loaded else {
            return .feesIsBeingCalculated
        }

        guard payingWallet != nil else {
            return .payingFeeWalletNotFound
        }

        // paying with SOL
        if payingWallet?.isNativeSOL == true {
            guard let wallet = walletsRepository.nativeWallet else {
                return .nativeWalletNotFound
            }

            let feeInSOL = feesSubject.value?.transactionFees(of: "SOL") ?? 0

            if feeInSOL > (wallet.lamports ?? 0) {
                return .notEnoughSOLToCoverFees
            }
        }

        // paying with SPL token
        else {
            // TODO: - fee compensation
            //                if feeCompensationPool == nil {
            //                    return L10n.feeCompensationPoolNotFound
            //                }
            if let payingWallet = payingWallet, let feeTotal = feesSubject.value?.totalLamport {
                if payingWallet.token.symbol == feesSubject.value?.totalToken?.symbol {
                    if feeTotal > (payingWallet.lamports ?? 0) {
                        return .notEnoughBalanceToCoverFees
                    }
                }
            }
        }

        // slippage
        if !isSlippageValid() {
            return .slippageIsNotValid
        }

        return nil
    }

    private func isSlippageValid() -> Bool {
        slippage <= .maxSlippage && slippage > 0
    }

    func feesRequest() async throws -> [PayingFee] {
        guard
            let sourceWallet = sourceWallet,
            let destinationWallet = destinationWallet
        else {
            return []
        }

        let bestPoolsPair = bestPoolsPair
        let inputAmount = inputAmount
        let slippage = slippage

        return try await swapService.getFees(
            sourceMint: sourceWallet.mintAddress,
            destinationAddress: destinationWallet.pubkey,
            destinationToken: destinationWallet.token,
            bestPoolsPair: bestPoolsPair,
            payingWallet: payingWallet,
            inputAmount: inputAmount,
            slippage: slippage
        ).fees
    }
}
