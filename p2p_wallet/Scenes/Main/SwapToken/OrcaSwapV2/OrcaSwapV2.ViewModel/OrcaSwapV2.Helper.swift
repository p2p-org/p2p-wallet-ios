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
        if loadingStateSubject.value != .loaded {
            return .swappingIsNotAvailable
        }

        // source wallet
        guard let sourceWallet = sourceWalletSubject.value else {
            return .sourceWalletIsEmpty
        }

        // destination wallet
        guard let destinationWallet = destinationWalletSubject.value else {
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
        guard let inputAmount = inputAmountSubject.value else {
            return .inputAmountIsEmpty
        }

        if inputAmount.rounded(decimals: sourceWallet.token.decimals) <= 0 {
            return .inputAmountIsNotValid
        }

        if inputAmount.rounded(decimals: sourceWallet.token.decimals) > availableAmountSubject.value?
            .rounded(decimals: sourceWallet.token.decimals)
        {
            return .insufficientFunds
        }

        // estimated amount
        guard let estimatedAmount = estimatedAmountSubject.value else {
            return .estimatedAmountIsNotValid
        }

        if estimatedAmount.rounded(decimals: destinationWallet.token.decimals) <= 0 {
            return .estimatedAmountIsNotValid
        }

        // best pools pairs
        if bestPoolsPairSubject.value == nil {
            return .bestPoolsPairsIsEmpty
        }

        // fees
        if feesSubject.state.isError {
            return .couldNotCalculatingFees
        }

        guard feesSubject.state == .loaded else {
            return .feesIsBeingCalculated
        }

        guard payingWalletSubject.value != nil else {
            return .payingFeeWalletNotFound
        }

        // paying with SOL
        if payingWalletSubject.value?.isNativeSOL == true {
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
            if let payingWallet = payingWalletSubject.value, let feeTotal = feesSubject.value?.totalLamport {
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
        slippageSubject.value <= .maxSlippage && slippageSubject.value > 0
    }

    func feesRequest() async throws -> [PayingFee] {
        guard
            let sourceWallet = sourceWalletSubject.value,
            let destinationWallet = destinationWalletSubject.value
        else {
            return []
        }

        let bestPoolsPair = bestPoolsPairSubject.value
        let inputAmount = inputAmountSubject.value
        let slippage = slippageSubject.value

        return try await swapService.getFees(
            sourceMint: sourceWallet.mintAddress,
            destinationAddress: destinationWallet.pubkey,
            destinationToken: destinationWallet.token,
            bestPoolsPair: bestPoolsPair,
            payingWallet: payingWalletSubject.value,
            inputAmount: inputAmount,
            slippage: slippage
        ).fees
    }
}
