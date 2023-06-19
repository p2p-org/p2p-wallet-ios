//
//  ReauthenticationWithoutDeviceShare.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Combine
import Foundation
import Onboarding

enum ReauthenticationWithoutDeviceShareResult {
    case success(TKeyFacade)
    case failure(Error)
    case cancel
}

final class ReauthenticationWithoutDeviceShareCoordinator: Coordinator<ReauthenticationWithoutDeviceShareResult> {
    private let navigationController: UINavigationController

    let viewModel: ReauthenticationWithoutDeviceShareViewModel

    let customShareDelegatedCoordinator: ReauthenticationCustomShareDelegatedCoordinator
    let socialShareDelegatedCoordinator: ReAuthSocialShareDelegatedCoordinator

    var previousNavigationStack: [UIViewController] = []
    var currentNavigationStack: [UIViewController] = [] {
        didSet {
            navigationController.setViewControllers(
                previousNavigationStack + currentNavigationStack,
                animated: true
            )
        }
    }

    let result = PassthroughSubject<ReauthenticationWithoutDeviceShareResult, Never>()

    init(
        facade: TKeyFacade,
        metadata: WalletMetaData,
        navigationController: UINavigationController
    ) {
        viewModel = .init(facade: facade, metadata: metadata)
        self.navigationController = navigationController

        customShareDelegatedCoordinator = .init(stateMachine: .init(callback: { [weak viewModel] event in
            try await viewModel?.stateMachine.accept(event: .customShareEvent(event))
        }))

        socialShareDelegatedCoordinator = .init(stateMachine: .init(callback: { [weak viewModel] event in
            try await viewModel?.stateMachine.accept(event: .socialShareEvent(event))
        }))
    }

    override func start() -> AnyPublisher<ReauthenticationWithoutDeviceShareResult, Never> {
        customShareDelegatedCoordinator.rootViewController = navigationController
        socialShareDelegatedCoordinator.rootViewController = navigationController

        guard let viewController = buildViewController(state: viewModel.stateMachine.currentState) else {
            return Empty().eraseToAnyPublisher()
        }

        previousNavigationStack = navigationController.viewControllers
        currentNavigationStack = [viewController]

        viewModel.stateMachine
            .stateStream
            .removeDuplicates()
            .dropFirst()
            .pairwise()
            .receive(on: RunLoop.main)
            .sink { [weak self] pairwise in
                self?.stateChangeHandler(from: pairwise.previous, to: pairwise.current)
            }
            .store(in: &subscriptions)

        return result
            .prefix(1)
            .eraseToAnyPublisher()
    }

    private func buildViewController(state: ReauthenticationWithoutDeviceShareState) -> UIViewController? {
        switch state {
        case let .customShare(innerState):
            return customShareDelegatedCoordinator.buildViewController(for: innerState)
        case let .socialShare(innerState, _):
            return socialShareDelegatedCoordinator.buildViewController(for: innerState)
        default:
            return nil
        }
    }

    private func stateChangeHandler(
        from: ReauthenticationWithoutDeviceShareState?,
        to: ReauthenticationWithoutDeviceShareState
    ) {
        switch to {
        case .finish:
            currentNavigationStack = []
            result.send(.success(viewModel.facade))
            return

        case .cancel:
            currentNavigationStack = []
            result.send(.cancel)
            return

        default:
            break
        }

        // TODO: Add empty screen
        let vc = buildViewController(state: to) ?? UIViewController()

        if to.step >= (from?.step ?? -1) {
            currentNavigationStack = [vc]
        } else {
            currentNavigationStack = [vc] + currentNavigationStack
            navigationController.popToViewController(vc, animated: true)
        }
    }
}
