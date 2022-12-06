//
//  SendCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 13.11.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver

final class SendCoordinator: Coordinator<SendCoordinator.Result> {
    
    // MARK: - Properties

    private let navigationController: UINavigationController
    private let pubKey: String?
    private let analyticsManager: AnalyticsManager
    private var sendCoordinator: SendToken.Coordinator?

    private let subject = PassthroughSubject<SendCoordinator.Result, Never>()

    // MARK: - Initializer

    init(
        navigationController: UINavigationController,
        pubKey: String?,
        analyticsManager: AnalyticsManager = Resolver.resolve()
    ) {
        self.navigationController = navigationController
        self.pubKey = pubKey
        self.analyticsManager = analyticsManager
    }

    override func start() -> AnyPublisher<SendCoordinator.Result, Never> {
        let viewModel = SendToken.ViewModel(
            walletPubkey: pubKey,
            relayMethod: .default
        )
        sendCoordinator = SendToken.Coordinator(
            viewModel: viewModel,
            navigationController: navigationController
        )
        analyticsManager.log(event: AmplitudeEvent.mainScreenSendOpen)

        sendCoordinator?.doneHandler = { [weak self] in
            self?.navigationController.popToRootViewController(animated: true)
            self?.subject.send(.done)
        }
        let view = sendCoordinator?.start(hidesBottomBarWhenPushed: true)
        view?.onClose = { [weak self] in
            self?.subject.send(.cancel)
        }

        return subject.prefix(1).eraseToAnyPublisher()
    }
}

// MARK: - Result

extension SendCoordinator {
    enum Result {
        case cancel
        case done
    }
}
