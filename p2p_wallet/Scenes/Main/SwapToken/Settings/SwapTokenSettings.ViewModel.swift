//
//  SwapTokenSettings.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import Combine
import Foundation
import Resolver
import SolanaSwift

protocol NewSwapTokenSettingsViewModelType: AnyObject {
    var navigationPublisher: AnyPublisher<SwapTokenSettings.NavigatableScene?, Never> { get }
    var possibleSlippageTypes: [SwapTokenSettings.SlippageType] { get }
    var slippageType: SwapTokenSettings.SlippageType { get }
    var feesContentPublisher: AnyPublisher<[SwapTokenSettings.FeeCellContent], Never> { get }
    var customSlippageIsOpenedPublisher: AnyPublisher<Bool, Never> { get }

    func slippageSelected(_ selected: SwapTokenSettings.SlippageType)
    func customSlippageChanged(_ value: Double?)
    func goBack()
}

extension SwapTokenSettings {
    @MainActor
    final class ViewModel: ObservableObject, NewSwapTokenSettingsViewModelType {
        // MARK: - Properties

        var slippageType: SwapTokenSettings.SlippageType {
            .init(doubleValue: swapViewModel.slippageSubject.value)
        }

        private let swapViewModel: OrcaSwapV2ViewModelType
        @Injected private var walletRepository: WalletsRepository
        @Injected private var notificationService: NotificationService

        // MARK: - Subject

        var customSlippageIsOpenedPublisher: AnyPublisher<Bool, Never> { $customSlippageIsOpened.eraseToAnyPublisher() }

        @Published private var navigation: NavigatableScene?
        @Published private var customSlippageIsOpened: Bool = false

        var feesContentPublisher: AnyPublisher<[FeeCellContent], Never> {
            Publishers.CombineLatest3(
                swapViewModel.sourceWalletPublisher,
                swapViewModel.destinationWalletPublisher,
                swapViewModel.feePayingTokenPublisher
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
            .eraseToAnyPublisher()
        }

        // MARK: NewSwapTokenSettingsViewModelType

        var possibleSlippageTypes: [SlippageType] {
            SlippageType.allCases
        }

        var navigationPublisher: AnyPublisher<NavigatableScene?, Never> {
            $navigation.eraseToAnyPublisher()
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
               customSlippageIsOpened
            {
                swapViewModel.slippageSubject.accept(value)
            }
        }

        func goBack() {
            navigation = .back
        }

        private func setCustomSlippageIsOpened(slippageType: SlippageType) {
            switch slippageType {
            case .oneTenth, .fiveTenth, .one:
                customSlippageIsOpened = false
            case .custom:
                customSlippageIsOpened = true
            }
        }
    }
}
