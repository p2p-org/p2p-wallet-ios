//
//  AppCoordinator.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/05/2022.
//

import AnalyticsManager
import Foundation
import KeyAppUI
import Reachability
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

    // MARK: - Properties

    var window: UIWindow?
    var isRestoration = false
    var showAuthenticationOnMainOnAppear = true
    var resolvedName: String?
    var reachability: Reachability?

    // MARK: - Initializers

    override init() {
        super.init()
        defer { Task { await appEventHandler.delegate = self } }
        reachability = try? Reachability()
    }

    // MARK: - Methods

    func start() {
        // set window
        window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = Defaults.appearance
        }

        openSplash()

        try? reachability?.startNotifier()

        reachability?.isReachable.filter { !$0 }
            .sink(receiveValue: { [weak self] _ in
                self?.notificationService.showToast(title: "☕️", text: L10n.YouReOffline.keepCalm)
            }).store(in: &subscriptions)
    }

    func reload() async {
        let account = await reloadData()
        navigate(account: account)
    }

    // MARK: - Navigation

    func oldOnboardingFlow() {
        // TODO: - Change to CreateOrRestoreWallet.Coordinator.start()
        let vm = CreateOrRestoreWallet.ViewModel()
        let vc = CreateOrRestoreWallet.ViewController(viewModel: vm)
        let nc = UINavigationController(rootViewController: vc)
        hideLoadingAndTransitionTo(nc)
    }

    func navigateToOnboarding() {
        // TODO: - Change to Onboarding.Coordinator.start()
        let vm = Onboarding.ViewModel()
        let vc = Onboarding.ViewController(viewModel: vm)
        hideLoadingAndTransitionTo(vc)
    }

    func navigateToOnboardingDone() {
        // TODO: - Change to Onboarding.Coordinator.start()
        let vc = WelcomeViewController(isReturned: isRestoration, name: resolvedName)
        vc.finishSetupHandler = { [weak self] in
            self?.finishSetUp()
        }
        hideLoadingAndTransitionTo(vc)
    }

    func navigateToMain() {
        // TODO: - Change to Main.Coordinator.start()
        let vm = Main.ViewModel()
        let vc = Main.ViewController(viewModel: vm)
        vc.authenticateWhenAppears = showAuthenticationOnMainOnAppear
        hideLoadingAndTransitionTo(vc)
    }

    func finishSetUp() {
        analyticsManager.log(event: .setupFinishClick)
        Task { await reload() }
    }

    private func navigate(account: Account?) {
        if account == nil {
            showAuthenticationOnMainOnAppear = false
            if available(.newOnboardingFlow) {
                newOnboardingFlow()
            } else {
                oldOnboardingFlow()
            }
        } else if storage.pinCode == nil ||
            !Defaults.didSetEnableBiometry ||
            !Defaults.didSetEnableNotifications
        {
            showAuthenticationOnMainOnAppear = false
            navigateToOnboarding()
        } else {
            navigateToMain()
        }
    }

    private func openSplash() {
        let vc = SplashViewController()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        Task { await warmup() }
    }

    private func warmup() async {
        await Resolver.resolve(WarmupManager.self).start()
        let account = await reloadData()

        if let splashVC = window?.rootViewController as? SplashViewController {
            splashVC.completionHandler = { [weak self] in
                self?.navigate(account: account)
            }
        } else {
            navigate(account: account)
        }
    }

    private func newOnboardingFlow() {
        guard let window = window else { return }
        let provider = Resolver.resolve(StartOnboardingNavigationProvider.self)
        let startCoordinator = provider.startCoordinator(for: window)

        coordinate(to: startCoordinator)
            .sink(receiveValue: { value in
                debugPrint(value)
            })
            .store(in: &subscriptions)
    }

    deinit {
        reachability?.stopNotifier()
    }

    // MARK: - Helper

    private func hideLoadingAndTransitionTo(_ vc: UIViewController) {
        window?.rootViewController?.view.hideLoadingIndicatorView()
        window?.rootViewController = vc
    }

    private func reloadData() async -> Account? {
        // reload session
        ResolverScope.session.reset()

        // try to retrieve account from seed
        try? await storage.reloadSolanaAccount()
        return storage.account
    }
}

extension UIWindow {
    func animate(newRootViewController: UIViewController) {
        rootViewController = newRootViewController
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {}, completion: nil)
    }
}
