//
// Created by Giang Long Tran on 01.02.2022.
//

import Foundation
import RxSwift

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

        if inputAmount > calculateAvailableAmount() {
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

        // paying with SOL
        if payingTokenModeSubject.value == .nativeSOL {
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
            let feeInToken = feesSubject.value?.transactionFees(of: sourceWallet.token.symbol) ?? 0
            if feeInToken > (sourceWallet.lamports ?? 0) {
                return .notEnoughBalanceToCoverFees
            }
        }

        // slippage
        if !isSlippageValid() {
            return .slippageIsNotValid
        }

        return nil
    }

    func calculateAvailableAmount() -> Double? {
        guard let sourceWallet = sourceWalletSubject.value,
            let fees = feesSubject.value?.transactionFees(of: sourceWallet.token.symbol)
        else {
            return sourceWalletSubject.value?.amount
        }

        // paying with native wallet
        if payingTokenModeSubject.value == .nativeSOL && !sourceWallet.isNativeSOL {
            return sourceWallet.amount
        }
        // paying with wallet itself
        else {
            let availableAmount =
                (sourceWallet.amount ?? 0) - fees.convertToBalance(decimals: sourceWallet.token.decimals)
            return availableAmount > 0 ? availableAmount : 0
        }
    }

    private func isSlippageValid() -> Bool {
        slippageSubject.value <= .maxSlippage && slippageSubject.value > 0
    }

    func feesRequest() -> Single<[PayingFee]> {
        Single.create { [weak self] observer in

            guard let self = self else {
                observer(.success([]))
                return Disposables.create()
            }

            guard let sourceWallet = self.sourceWalletSubject.value,
                let sourceWalletPubkey = sourceWallet.pubkey,
                let lamportsPerSignature = self.feeService.lamportsPerSignature,
                let minRenExempt = self.feeService.minimumBalanceForRenExemption
            else {
                observer(.success([]))
                return Disposables.create()
            }

            let destinationWallet = self.destinationWalletSubject.value
            let bestPoolsPair = self.bestPoolsPairSubject.value
            let inputAmount = self.inputAmountSubject.value
            let myWalletsMints = self.walletsRepository.getWallets().compactMap { $0.token.address }
            let slippage = self.slippageSubject.value

            guard
                let feeInfo = try? self.swapService.getFees(
                    sourceAddress: sourceWalletPubkey,
                    availableSourceMintAddresses: myWalletsMints,
                    destinationAddress: destinationWallet?.pubkey,
                    destinationToken: destinationWallet?.token,
                    bestPoolsPair: bestPoolsPair,
                    inputAmount: inputAmount,
                    slippage: slippage,
                    lamportsPerSignature: lamportsPerSignature,
                    minRentExempt: minRenExempt
                )
            else {
                observer(.success([]))
                return Disposables.create()
            }

            observer(.success(feeInfo.fees))
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }
}
