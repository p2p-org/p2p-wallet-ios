import AnalyticsManager
import Combine
import Foundation
import Resolver
import SafariServices
import Sell
import SwiftUI
import UIKit

enum SellCoordinatorResult {
    case completed
    case interupted
    case none
}

final class SellCoordinator: Coordinator<SellCoordinatorResult> {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var sellDataService: any SellDataService

    // MARK: - Properties

    private var navigation = PassthroughSubject<SellNavigation?, Never>()
    private let navigationController: UINavigationController
    private var viewModel: SellViewModel!
    private let resultSubject = PassthroughSubject<SellCoordinatorResult, Never>()
    // TODO: Pass initial amount in token to view model
    private let initialAmountInToken: Double?
    private var isCompleted = false
    private var navigatedFromMoonpay = false
    private var transition: PanelTransition?
    private var moonpayInfoViewController: UIViewController?

    // MARK: - Initializer

    init(initialAmountInToken: Double? = nil, navigationController: UINavigationController) {
        self.initialAmountInToken = initialAmountInToken
        self.navigationController = navigationController
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<SellCoordinatorResult, Never> {
        // create viewController
        viewModel = SellViewModel(initialBaseAmount: initialAmountInToken, navigation: navigation)
        let vc = UIHostingController(rootView: SellView(viewModel: viewModel))
        vc.hidesBottomBarWhenPushed = navigationController.canHideBottomForNextPush
        navigationController.pushViewController(vc, animated: true)
        setTitle(to: vc)

        // scene navigation
        navigation
            .compactMap { $0 }
            .flatMap { [unowned self] in
                navigate(to: $0)
            }
            .sink { _ in }
            .store(in: &subscriptions)

        viewModel.back
            .sink(receiveValue: { [unowned self] in
                // pop viewcontroller and resultSubject.send(.none)
                navigationController.popViewController(animated: true)
            })
            .store(in: &subscriptions)

        viewModel.presentSOLInfo
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.viewModel?.isEnteringBaseAmount = false
            })
            .flatMap { [unowned self, unowned vc] _ in
                self.coordinate(to: SellSOLInfoCoordinator(parentController: vc))
                    .handleEvents(receiveOutput: { [weak self] in
                        self?.viewModel?.isEnteringBaseAmount = true
                    })
            }
            .sink {}
            .store(in: &subscriptions)

        vc.deallocatedPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                if !self.isCompleted {
                    self.resultSubject.send(.none)
                }
            }
            .store(in: &subscriptions)

        return resultSubject
            .prefix(1)
            .eraseToAnyPublisher()
    }

    private func setTitle(to vc: UIViewController) {
        vc.title = "\(L10n.cashoutWithMoonpay) "
        vc.navigationController?.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Navigation

    private func navigate(to scene: SellNavigation) -> AnyPublisher<Void, Never> {
        switch scene {
        case let .webPage(url):
            return navigateToProviderWebPage(url: url)
                .deallocatedPublisher()
                .handleEvents(receiveCompletion: { [weak self] _ in
                    self?.viewModel.warmUp()
                    self?.navigatedFromMoonpay = true
                    self?.viewModel.shouldNotShowKeyboard = false
                }).eraseToAnyPublisher()

        case let .showPending(transactions, fiat):
            return Publishers.MergeMany(
                transactions.map { transaction in
                    coordinate(
                        to: SellPendingCoordinator(
                            transaction: transaction,
                            fiat: fiat,
                            navigationController: navigationController,
                            navigatedFromMoonpay: navigatedFromMoonpay
                        )
                    )
                    .map { ($0, transaction) }
                }
            )
            .handleEvents(receiveOutput: { [weak self] result, sellTransaction in
                guard let self = self else { return }
                switch result {
                case .transactionRemoved:
                    self.navigationController.popViewController(animated: true)
                case .cancelled:
                    // pop to rootViewController and resultSubject.send(.none)
                    self.navigationController.popToRootViewController(animated: true)
                case .cashOutInterupted:
                    if self.navigatedFromMoonpay {
                        self.resultSubject.send(.interupted)
                    } else {
                        self.navigationController.popToRootViewController(animated: true)
                    }
                case let .transactionSent(transaction):
                    // mark as completed
                    self.isCompleted = true

                    // pop to rootViewController
                    self.navigationController.popToRootViewController(animated: true)

                    // mark as pending handly, as server may return status a little bit later
                    Task {
                        await self.sellDataService.markAsPending(id: sellTransaction.id)
                    }

                    // Show status
                    self.navigateToSendTransactionStatus(model: transaction)
                }
                self.navigatedFromMoonpay = false
            })
            .map { _ in }
            .eraseToAnyPublisher()

        case .moonpayInfo:
            moonpayInfoViewController = UIHostingController(
                rootView: MoonpayInfoView(
                    actionButtonPressed: { [weak self] isChecked in
                        if isChecked {
                            Defaults.moonpayInfoShouldHide = true
                        }
                        self?.moonpayInfoViewController?.dismiss(animated: true) {
                            self?.analyticsManager.log(event: .sellMoonpayOpenNotification)
                            self?.viewModel.openProviderWebView()
                        }
                    },
                    isChecked: false
                )
            )
            guard let moonpayInfoViewController else { return Just(()).eraseToAnyPublisher() }
            transition = PanelTransition()
            transition?.containerHeight = 541.adaptiveHeight
            transition?.dimmClicked.sink(receiveValue: { [weak self] _ in
                self?.moonpayInfoViewController?.dismiss(animated: true)
            }).store(in: &subscriptions)
            moonpayInfoViewController.view.layer.cornerRadius = 20
            moonpayInfoViewController.transitioningDelegate = transition
            moonpayInfoViewController.modalPresentationStyle = .custom
            navigationController.viewControllers.last?.present(moonpayInfoViewController, animated: true)
            return moonpayInfoViewController.deallocatedPublisher()
        }
    }

    private func navigateToProviderWebPage(url: URL) -> UIViewController {
        let vc = SFSafariViewController(url: url)
        vc.modalPresentationStyle = .automatic
        navigationController.present(vc, animated: true)
        analyticsManager.log(event: .sellMoonpay)
        return vc
    }

    private func navigateToSendTransactionStatus(model: SendTransaction) {
        coordinate(to: SendTransactionStatusCoordinator(parentController: navigationController, transaction: model))
            .sink(receiveCompletion: { [weak self] _ in
                self?.resultSubject.send(.completed)
            }, receiveValue: {})
            .store(in: &subscriptions)
    }
}
