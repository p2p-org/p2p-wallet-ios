//
//  WormholeClaimViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Wormhole

class WormholeClaimViewModel: BaseViewModel, ObservableObject {
    let action: PassthroughSubject<Action, Never> = .init()

    let bundle: AsyncValue<WormholeBundle?>

    @Published var model: any WormholeClaimModel
    @Published var feeAmountInFiat: String = ""

    init(model: WormholeClaimMockModel) {
        self.model = model
        self.bundle = .init(just: nil)

        super.init()
    }

    init(
        account: EthereumAccountsService.Account,
        ethereumAccountsService: EthereumAccountsService = Resolver.resolve(),
        wormholeAPI: WormholeService = Resolver.resolve(),
        notificationService: NotificationService = Resolver.resolve()
    ) {
        self.model = WormholeClaimEthereumModel(account: account)
        self.bundle = .init(initialItem: nil) {
            // Request to get bundle
            do {
                return try await (wormholeAPI.getBundle(account: account), nil)
            } catch {
                return (nil, error)
            }
        }

        super.init()

        // Start fetch bundle
        bundle.fetch()

        // Listen changing in bundle value
        bundle.listen(target: self, in: &subscriptions)

        // Update fee
        bundle.$state
            .map(\.value?.fees)
            .receive(on: RunLoop.main)
            .sink { [weak self] fees in
                guard let self = self else { return }

                if let fees {
                    self.feeAmountInFiat = CurrencyFormatter().string(
                        for: CurrencyAmount(value: fees.totalInUSD, currencyCode: "USD")
                    ) ?? "N/A"
                } else {
                    self.feeAmountInFiat = L10n.isUnavailable(L10n.value)
                }
            }
            .store(in: &subscriptions)

        // Update timer
        bundle.$state
            .map(\.value?.expiresAtDate)
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] expiresAtDate in
                guard let self = self else { return }

                let elapsed = expiresAtDate.timeIntervalSince(Date()) - 1

                DispatchQueue.main.asyncAfter(deadline: .now() + elapsed) { [weak self] in
                    self?.bundle.fetch()
                }
            }
            .store(in: &subscriptions)

        // Update error
        bundle.$state
            .map(\.error)
            .compactMap { $0 }
            .sink { error in
                notificationService.showInAppNotification(.error("\(error.localizedDescription)"))
            }
            .store(in: &subscriptions)
    }

    func claim() {
        if let model = model as? WormholeClaimEthereumModel {
            guard let bundle = bundle.state.value else {
                Error.missingBundle.capture()
                return
            }

            let rawTransaction = WormholeClaimTransaction(
                wormholeService: Resolver.resolve(),
                token: model.account.token,
                amountInCrypto: model.account.representedBalance,
                amountInFiat: model.account.balanceInFiat,
                bundle: bundle
            )

            let transactionHandler: TransactionHandler = Resolver.resolve()
            let index = transactionHandler.sendTransaction(rawTransaction)
            let pendingTransaction = transactionHandler.getProcessingTransaction(index: index)

            action.send(.claiming(pendingTransaction))
        }
    }
}

extension WormholeClaimViewModel {
    enum Action {
        case openFee(AsyncValue<WormholeBundle?>)
        case claiming(PendingTransaction)
    }

    enum Error: Swift.Error {
        case missingBundle
    }
}
