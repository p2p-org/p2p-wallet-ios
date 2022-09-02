//
//  AppCoordinator.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/05/2022.
//

import AnalyticsManager
import Combine
import Foundation
import KeyAppUI
import Onboarding
import Resolver
import SolanaSwift
import UIKit

class AppCoordinator: Coordinator<Void> {
    // MARK: - Dependencies

    private var appEventHandler: AppEventHandlerType = Resolver.resolve()
    private let storage: AccountStorageType & PincodeStorageType & NameStorageType = Resolver.resolve()
    let analyticsManager: AnalyticsManager = Resolver.resolve()
    let notificationsService: NotificationService = Resolver.resolve()

    @Injected var notificationService: NotificationService
    @Injected var userWalletManager: UserWalletManager

    // MARK: - Properties

    var window: UIWindow?
    var isRestoration = false
    var showAuthenticationOnMainOnAppear = true
    var resolvedName: String?

    var reloadEvent: PassthroughSubject<Void, Never> = .init()

    // MARK: - Initializers

    override init() {
        super.init()
        defer { Task { await appEventHandler.delegate = self } }
    }

    // MARK: - Methods

    func start() {
        // set window
        window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = Defaults.appearance
        }

        openSplash { [self] in
            userWalletManager
                .$wallet
                .combineLatest(
                    reloadEvent
                        .map { _ in }
                        .prepend(())
                )
                .receive(on: RunLoop.main)
                .sink { wallet, _ in
                    print("Here")
                    print(wallet)
                    wallet != nil ? navigateToMain() : newOnboardingFlow()
                }
                .store(in: &subscriptions)
        }
    }

    // MARK: - Navigation

    func navigateToMain() {
        // TODO: - Change to Main.Coordinator.start()
        let vm = Main.ViewModel()
        let vc = Main.ViewController(viewModel: vm)
        vc.authenticateWhenAppears = showAuthenticationOnMainOnAppear
        hideLoadingAndTransitionTo(vc)
    }

    private func navigate(account: Account?) {
        if account == nil {
            newOnboardingFlow()
        } else {
            navigateToMain()
        }
    }

    private func openSplash(_ completionHandler: @escaping () -> Void) {
        let vc = SplashViewController()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        // warmup
        Task {
            await Resolver.resolve(WarmupManager.self).start()
            try await userWalletManager.refresh()

            if let splashVC = window?.rootViewController as? SplashViewController {
                splashVC.stop(completionHandler: completionHandler)
            } else {
                completionHandler()
            }
        }
    }

    private func newOnboardingFlow() {
        guard let window = window else { return }
        let provider = Resolver.resolve(StartOnboardingNavigationProvider.self)
        let startCoordinator = provider.startCoordinator(for: window)

        coordinate(to: startCoordinator)
            .sinkAsync(receiveValue: { [unowned self] result in
                let userWalletManager: UserWalletManager = Resolver.resolve()
                switch result {
                case let .created(data):
                    analyticsManager.log(event: .setupOpen(fromPage: "create_wallet"))

                    try await userWalletManager.add(
                        seedPhrase: data.wallet.seedPhrase.components(separatedBy: " "),
                        derivablePath: data.wallet.derivablePath,
                        name: nil,
                        deviceShare: data.deviceShare,
                        ethAddress: data.ethAddress
                    )

                    saveSecurity(data: data.security)
                case let .restored(data):
                    try await userWalletManager.add(
                        seedPhrase: data.wallet.seedPhrase.components(separatedBy: " "),
                        derivablePath: data.wallet.derivablePath,
                        name: nil,
                        deviceShare: nil,
                        ethAddress: data.ethAddress
                    )

                    saveSecurity(data: data.security)
                }

                showAuthenticationOnMainOnAppear = false
            })
            .store(in: &subscriptions)
    }

    private func saveSecurity(data: SecurityData) {
        Resolver.resolve(PincodeStorageType.self).save(data.pincode)
        Defaults.isBiometryEnabled = data.isBiometryEnabled
    }

    // MARK: - Helper

    private func hideLoadingAndTransitionTo(_ vc: UIViewController) {
        window?.rootViewController?.view.hideLoadingIndicatorView()
        window?.rootViewController = vc
    }
}

extension UIWindow {
    func animate(newRootViewController: UIViewController) {
        rootViewController = newRootViewController
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {}, completion: nil)
    }
}
