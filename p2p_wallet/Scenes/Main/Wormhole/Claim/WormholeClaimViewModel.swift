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

    init(model: WormholeClaimMockModel) {
        self.model = model
        bundle = .init(just: nil)

        super.init()
    }

    init(
        account: EthereumAccount,
        ethereumAccountsService _: EthereumAccountsService = Resolver.resolve(),
        wormholeAPI: WormholeService = Resolver.resolve(),
        notificationService: NotificationService = Resolver.resolve()
    ) {
        model = WormholeClaimEthereumModel(account: account, bundle: .init(value: nil))
        bundle = .init(initialItem: nil) {
            // Request to get bundle
            do {
                return try await(wormholeAPI.getBundle(account: account), nil)
            } catch {
                return (nil, error)
            }
        }

        super.init()

        // Start fetch bundle
        bundle.fetch()

        // Listen changing in bundle value
        bundle.listen(target: self, in: &subscriptions)

        bundle.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.model = WormholeClaimEthereumModel(account: account, bundle: state)
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

        // Notify user an error
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
            if bundle.state.hasError {
                bundle.fetch()
            } else {
                guard let bundle = bundle.state.value else {
                    Error.missingBundle.capture()
                    return
                }

                let userActionService: UserActionService = Resolver.resolve()

                let userAction = WormholeClaimUserAction(
                    token: model.account.token,
                    bundle: bundle
                )

                userActionService.execute(action: userAction)
                action.send(.claiming(userAction))
            }
        }
    }
}

extension WormholeClaimViewModel {
    enum Action {
        case openFee(AsyncValue<WormholeBundle?>)
        case claiming(WormholeClaimUserAction)
    }

    enum Error: Swift.Error {
        case missingBundle
    }
}
