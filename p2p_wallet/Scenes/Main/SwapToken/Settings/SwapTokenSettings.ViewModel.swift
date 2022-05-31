//
//  SwapTokenSettings.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift

protocol NewSwapTokenSettingsViewModelType: AnyObject {
    var navigationDriver: Driver<SwapTokenSettings.NavigatableScene?> { get }
    var possibleSlippageTypes: [SwapTokenSettings.SlippageType] { get }
    var slippageType: SwapTokenSettings.SlippageType { get }
    var feesContentDriver: Driver<[SwapTokenSettings.FeeCellContent]> { get }
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

        private let swapViewModel: OrcaSwapV2ViewModelType
        @Injected private var walletRepository: WalletsRepository
        @Injected private var notificationService: NotificationService

        // MARK: - Subject

        var customSlippageIsOpenedDriver: Driver<Bool> { customSlippageIsOpenedSubject.asDriver() }

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let customSlippageIsOpenedSubject = BehaviorRelay<Bool>(value: false)

        var feesContentDriver: Driver<[FeeCellContent]> {
            Driver.combineLatest(
                swapViewModel.sourceWalletDriver,
                swapViewModel.destinationWalletDriver,
                swapViewModel.feePayingTokenDriver
            ).map { [weak self] _, _, feePayingToken in
                guard let self = self else { return [] }
                var list: [FeeCellContent] = []

                for wallet in self.walletRepository.getWallets().filter({ wallet in wallet.amount > 0 }) {
                    list.append(
                        .init(
                            wallet: wallet,
                            tokenLabelText: wallet.token.symbol,
                            isSelected: feePayingToken == wallet,
                            onTapHandler: { [weak self] in
                                self?.swapViewModel.changeFeePayingToken(to: wallet)
                            }
                        )
                    )
                }

                return list
            }
        }

        // MARK: NewSwapTokenSettingsViewModelType

        var possibleSlippageTypes: [SlippageType] {
            SlippageType.allCases
        }

        var navigationDriver: Driver<NavigatableScene?> {
            navigationSubject.asDriver()
        }

        // MARK: - Actions

        init(
            nativeWallet _: Wallet?,
            swapViewModel: OrcaSwapV2ViewModelType
        ) {
            self.swapViewModel = swapViewModel

            setCustomSlippageIsOpened(slippageType: slippageType)
        }

        func slippageSelected(_ selected: SlippageType) {
            setCustomSlippageIsOpened(slippageType: selected)

            guard let doubleSlippage = selected.doubleValue else { return }

            swapViewModel.slippageSubject.accept(doubleSlippage)
            notificationService.showInAppNotification(.done(L10n.thePriceSlippageWasSetAt(selected.description)))
        }

        func customSlippageChanged(_ value: Double?) {
            if let value = SlippageType.custom(value).doubleValue,
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
