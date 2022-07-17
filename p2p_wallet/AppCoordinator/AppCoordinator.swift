//
//  AppCoordinator.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/05/2022.
//

import AnalyticsManager
import Foundation
import Resolver
import SolanaSwift
import UIKit

class AppCoordinator {
    // MARK: - Dependencies

    private var appEventHandler: AppEventHandlerType = Resolver.resolve()
    private let storage: AccountStorageType & PincodeStorageType & NameStorageType = Resolver.resolve()
    let analyticsManager: AnalyticsManager = Resolver.resolve()
    let notificationsService: NotificationService = Resolver.resolve()

    // MARK: - Properties

    var window: UIWindow?
    let lockView = LockView()
    let indicator = WLLoadingIndicatorView(isBlocking: true)
    var isRestoration = false
    var showAuthenticationOnMainOnAppear = true
    var resolvedName: String?

    // MARK: - Initializers

    init() {
        defer { appEventHandler.delegate = self }
    }

    // MARK: - Methods

    func start() {
        // set window
        window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = Defaults.appearance
        }

        // add placeholder
        window?.rootViewController = BaseVC()
        window?.makeKeyAndVisible()

        Task { await reload() }
    }

    func reload() async {
        // remove rootvc, show loading
        await MainActor.run {
            removeRootViewControllerAndShowLoading()
        }

        // reload session
        ResolverScope.session.reset()

        // try to retrieve account from seed
        try? await storage.reloadSolanaAccount()
        let account = storage.account

        // show scene
        if account == nil {
            showAuthenticationOnMainOnAppear = false
            await MainActor.run {
                navigateToCreateOrRestoreWallet()
            }
        } else if storage.pinCode == nil ||
            !Defaults.didSetEnableBiometry ||
            !Defaults.didSetEnableNotifications
        {
            showAuthenticationOnMainOnAppear = false
            await MainActor.run {
                navigateToOnboarding()
            }
        } else {
            await MainActor.run {
                navigateToMain()
            }
        }

        // remove lockview
        await MainActor.run {
            lockView.removeFromSuperview()
            indicator.removeFromSuperview()
        }
    }

    // MARK: - Navigation

    func navigateToCreateOrRestoreWallet() {
        // TODO: - Change to CreateOrRestoreWallet.Coordinator.start()
        let vm = CreateOrRestoreWallet.ViewModel()
        let vc = CreateOrRestoreWallet.ViewController(viewModel: vm)
        let nc = UINavigationController(rootViewController: vc)
        transition(to: nc)
    }

    func navigateToOnboarding() {
        // TODO: - Change to Onboarding.Coordinator.start()
        let vm = Onboarding.ViewModel()
        let vc = Onboarding.ViewController(viewModel: vm)
        transition(to: vc)
    }

    func navigateToOnboardingDone() {
        // TODO: - Change to Onboarding.Coordinator.start()
        let vc = WelcomeViewController(isReturned: isRestoration, name: resolvedName)
        vc.finishSetupHandler = { [weak self] in
            self?.finishSetUp()
        }
        transition(to: vc)
    }

    func navigateToMain() {
        // TODO: - Change to Main.Coordinator.start()
        let vm = Main.ViewModel()
        let vc = Main.ViewController(viewModel: vm)
        vc.authenticateWhenAppears = showAuthenticationOnMainOnAppear
        transition(to: vc)
    }

    func finishSetUp() {
        analyticsManager.log(event: .setupFinishClick)
        Task { await reload() }
    }

    // MARK: - Helper

    private func removeRootViewControllerAndShowLoading() {
        window?.rootViewController = nil
        // add lockview
        lockView.removeFromSuperview()
        window?.addSubview(lockView)
        lockView.autoPinEdgesToSuperviewEdges()

        // show loading
        indicator.removeFromSuperview()
        window?.addSubview(indicator)
        indicator.autoPinEdgesToSuperviewEdges()
    }

    private func transition(to vc: UIViewController) {
        window?.rootViewController = vc
    }
}
