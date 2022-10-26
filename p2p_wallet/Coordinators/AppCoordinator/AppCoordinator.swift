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
    @Injected var createNameService: CreateNameService

    // MARK: - Properties

    var window: UIWindow?
    var showAuthenticationOnMainOnAppear = true

    var reloadEvent: PassthroughSubject<Void, Never> = .init()

    private var walletCreated: Bool = false

    // MARK: - Initializers

    override init() {
        super.init()
        defer { Task { await appEventHandler.delegate = self } }
        Task { await bind() }
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
                .sink { [unowned self] wallet, _ in
                    if wallet != nil {
                        if self.walletCreated, available(.onboardingUsernameEnabled) {
                            self.openCreateUsername()
                        } else {
                            self.navigateToMain()
                        }
                    } else {
                        self.newOnboardingFlow()
                    }
                }
                .store(in: &subscriptions)
        }
    }

    // MARK: - Navigation

    private func openCreateUsername() {
        guard let window = window else { return }
        coordinate(to: CreateUsernameCoordinator(navigationOption: .onboarding(window: window)))
            .sink { [unowned self] in
                self.navigateToMain()
            }.store(in: &subscriptions)
    }

    func navigateToMain() {
        // TODO: - Change to Main.Coordinator.start()
        Task.detached {
            try await Resolver.resolve(WalletMetadataService.self).update()
        }

        let vm = Main.ViewModel()
        let vc = Main.ViewController(viewModel: vm)
        vc.authenticateWhenAppears = showAuthenticationOnMainOnAppear
        hideLoadingAndTransitionTo(vc)
    }

    private func openSplash(_ completionHandler: @escaping () -> Void) {
        // TODO: - Return for new splash screen
        // let vc = SplashViewController()
        // window?.rootViewController = vc
        // window?.makeKeyAndVisible()

        let vc = BaseVC()
        let lockView = LockView()
        vc.view.addSubview(lockView)
        lockView.autoPinEdgesToSuperviewEdges()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        // warmup
        Task {
            await Resolver.resolve(WarmupManager.self).start()
            try await userWalletManager.refresh()

            // if let splashVC = window?.rootViewController as? SplashViewController {
            //     splashVC.stop(completionHandler: completionHandler)
            // } else {
            completionHandler()
            // }
        }
    }

    private func newOnboardingFlow() {
        guard let window = window else { return }
        let provider = Resolver.resolve(StartOnboardingNavigationProvider.self)
        let startCoordinator = provider.startCoordinator(for: window)

        Task.detached {
            try await Resolver.resolve(WalletMetadataService.self).clear()
        }

        coordinate(to: startCoordinator)
            .sinkAsync(receiveValue: { [unowned self] result in
                showAuthenticationOnMainOnAppear = false
                let userWalletManager: UserWalletManager = Resolver.resolve()
                switch result {
                case let .created(data):
                    walletCreated = true

                    analyticsManager.log(event: AmplitudeEvent.setupOpen(fromPage: "create_wallet"))
                    analyticsManager.log(event: AmplitudeEvent.createConfirmPin(result: true))

                    // Setup user wallet
                    try await userWalletManager.add(
                        seedPhrase: data.wallet.seedPhrase.components(separatedBy: " "),
                        derivablePath: data.wallet.derivablePath,
                        name: nil,
                        deviceShare: data.deviceShare,
                        ethAddress: data.ethAddress
                    )

                    // Warmup metadata
                    Task.detached {
                        try await Resolver.resolve(WalletMetadataService.self).update(initialMetadata: data.metadata)
                    }

                    saveSecurity(data: data.security)
                case let .restored(data):
                    analyticsManager.log(event: AmplitudeEvent.restoreConfirmPin(result: true))

                    let restoreMethod: String = data.metadata == nil ? "seed" : "web3auth"
                    analyticsManager.setIdentifier(AmplitudeIdentifier.userRestoreMethod(restoreMethod: restoreMethod))

                    // Setup user wallet
                    try await userWalletManager.add(
                        seedPhrase: data.wallet.seedPhrase.components(separatedBy: " "),
                        derivablePath: data.wallet.derivablePath,
                        name: nil,
                        deviceShare: nil,
                        ethAddress: data.ethAddress
                    )

                    // Warmup metadata
                    if let metadata = data.metadata {
                        Task.detached {
                            try await Resolver.resolve(WalletMetadataService.self)
                                .update(initialMetadata: metadata)
                        }
                    }

                    saveSecurity(data: data.security)
                case .breakProcess:
                    newOnboardingFlow()
                }
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
        window?.animate(newRootViewController: vc)
    }

    private func bind() {
        createNameService.createNameResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSuccess in
                if isSuccess {
                    guard let view = self?.window?.rootViewController?.view else { return }
                    SnackBar(title: "🎉", icon: nil, text: L10n.nameWasBooked).show(in: view)
                } else {
                    self?.notificationService.showDefaultErrorNotification()
                }
            }.store(in: &subscriptions)
    }
}
