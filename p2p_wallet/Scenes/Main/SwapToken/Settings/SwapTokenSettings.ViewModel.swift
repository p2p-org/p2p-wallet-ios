//
//  SwapTokenSettings.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol NewSwapTokenSettingsViewModelType: AnyObject {
    var navigationDriver: Driver<SwapTokenSettings.NavigatableScene?> { get }
    var possibleSlippageTypes: [SwapTokenSettings.SlippageType] { get }
    var slippageType: SwapTokenSettings.SlippageType { get }
    var feesContent: [SwapTokenSettings.FeeCellContent] { get }
    var customSlippageIsOpenedDriver: Driver<Bool> { get }

    func slippageSelected(_ selected: SwapTokenSettings.SlippageType)
    func customSlippageChanged(_ value: Double?)
    func goBack()
}

extension SwapTokenSettings {
    final class ViewModel: NewSwapTokenSettingsViewModelType {
        // MARK: - Properties
        var slippageType: SwapTokenSettings.SlippageType {
            .init(doubleValue: swapViewModel.slippageSubject.value)
        }

        private let nativeWallet: Wallet?
        private let swapViewModel: OrcaSwapV2ViewModelType

        // MARK: - Subject
        var customSlippageIsOpenedDriver: Driver<Bool> { customSlippageIsOpenedSubject.asDriver() }

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let customSlippageIsOpenedSubject = BehaviorRelay<Bool>(value: false)

        // MARK: NewSwapTokenSettingsViewModelType
        lazy var feesContent: [FeeCellContent] = {
            var result: [FeeCellContent] = [
                .init(
                    wallet: nativeWallet,
                    tokenLabelText: nativeWallet?.token.symbol,
                    isSelected: swapViewModel.payingTokenSubject.value == .nativeSOL,
                    onTapHandler: { [weak self] in
                        self?.swapViewModel.changePayingToken(to: .nativeSOL)
                    }
                )
            ]

            if let tokensName = swapViewModel.transactionTokensName {
                result.append(
                    .init(
                        wallet: nil,
                        tokenLabelText: tokensName,
                        isSelected: swapViewModel.payingTokenSubject.value == .transactionToken,
                        onTapHandler: { [weak self] in
                            self?.swapViewModel.changePayingToken(to: .transactionToken)
                        }
                    )
                )
            }

            return result
        }()
        var possibleSlippageTypes: [SlippageType] {
            SlippageType.allCases
        }

        var navigationDriver: Driver<NavigatableScene?> {
            navigationSubject.asDriver()
        }

        // MARK: - Actions
        init(
            nativeWallet: Wallet?,
            swapViewModel: OrcaSwapV2ViewModelType
        ) {
            self.nativeWallet = nativeWallet
            self.swapViewModel = swapViewModel

            setCustomSlippageIsOpened(slippageType: slippageType)
        }

        func slippageSelected(_ selected: SlippageType) {
            setCustomSlippageIsOpened(slippageType: selected)

            guard let doubleSlippage = selected.doubleValue else { return }

            swapViewModel.slippageSubject.accept(doubleSlippage)
        }

        func customSlippageChanged(_ value: Double?) {
            if
                let value = SlippageType.custom(value).doubleValue,
                customSlippageIsOpenedSubject.value
            {
                swapViewModel.slippageSubject.accept(value)
            }
        }

        func goBack() {
            navigationSubject.accept(.back)
        }

        private func setCustomSlippageIsOpened(slippageType: SlippageType) {
            switch slippageType {
            case .oneTenth, .fiveTenth, .one:
                customSlippageIsOpenedSubject.accept(false)
            case .custom:
                customSlippageIsOpenedSubject.accept(true)
            }
        }
    }
}
