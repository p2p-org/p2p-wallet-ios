//
//  TabBarController.swift
//  p2p_wallet
//
//  Created by Ivan on 09.07.2022.
//

import AnalyticsManager
import Combine
import Intercom
import KeyAppUI
import Resolver
import Sell
import SwiftUI
import UIKit

final class TabBarController: UITabBarController {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var helpLauncher: HelpCenterLauncher
    @Injected private var sellDataService: any SellDataService
    @Injected private var solanaTracker: SolanaTracker

    // MARK: - Publishers

    var middleButtonClicked: AnyPublisher<Void, Never> { customTabBar.middleButtonClicked }
    private let homeTabClickedTwicelySubject = PassthroughSubject<Void, Never>()
    var homeTabClickedTwicely: AnyPublisher<Void, Never> { homeTabClickedTwicelySubject.eraseToAnyPublisher() }
    private let solendTutorialSubject = PassthroughSubject<Void, Never>()
    var solendTutorialClicked: AnyPublisher<Void, Never> { solendTutorialSubject.eraseToAnyPublisher() }
    private let jupiterSwapClickedSubject = PassthroughSubject<Void, Never>()
    var jupiterSwapClicked: AnyPublisher<Void, Never> { jupiterSwapClickedSubject.eraseToAnyPublisher() }

    // MARK: - Properties

    private var subscriptions = Set<AnyCancellable>()
    private let viewModel: TabBarViewModel
    private let authenticateWhenAppears: Bool

    private var customTabBar: CustomTabBar { tabBar as! CustomTabBar }
    private lazy var blurEffectView: UIView = LockView()
    private var localAuthVC: PincodeViewController?

    // MARK: - Initializers

    init(
        viewModel: TabBarViewModel,
        authenticateWhenAppears: Bool
    ) {
        self.viewModel = viewModel
        self.authenticateWhenAppears = authenticateWhenAppears
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public actions

    func setupTabs() {
        TabItem.allCases.enumerated().forEach { index, item in
            if item == .actions {
                viewControllers?[index].tabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)
            } else {
                viewControllers?[index].tabBarItem = UITabBarItem(
                    title: item.displayTitle,
                    image: item.image,
                    selectedImage: item.image
                )
            }
        }
    }

    func changeItem(to item: TabItem) {
        guard let viewControllers = viewControllers,
              item.rawValue < viewControllers.count
        else { return }
        let viewController = viewControllers[item.rawValue]
        selectedIndex = item.rawValue
        _ = tabBarController(self, shouldSelect: viewController)
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // replace default TabBar by CustomTabBar
        setValue(CustomTabBar(frame: tabBar.frame), forKey: "tabBar")

        // bind values
        bind()

        // set up
        setUpTabBarAppearance()
        delegate = self

        // authenticate if needed
        if authenticateWhenAppears {
            #if !DEBUG
            viewModel.authenticate(presentationStyle: .login())
            #endif
        }

        // add blur EffectView for authentication scene
        view.addSubview(blurEffectView)
        blurEffectView.autoPinEdgesToSuperviewEdges()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        tabBar.subviews.forEach { bar in
            bar.subviews.compactMap { $0 as? UILabel }.forEach {
                $0.adjustsFontSizeToFitWidth = true
            }
        }
    }

    // MARK: - Authentications
    
    private var lockWindow: UIWindow?
    
    private func setUpLockWindow() {
        lockWindow = UIWindow(frame: UIScreen.main.bounds)
        let lockVC = BaseVC()
        let lockView = LockView()
        lockVC.view.addSubview(lockView)
        lockView.autoPinEdgesToSuperviewEdges()
        lockWindow?.rootViewController = lockVC
    }

    private func showLockView() {
        setUpLockWindow()
        lockWindow?.makeKeyAndVisible()
        solanaTracker.stopTracking()
    }
    
    private func removeLockWindow() {
        lockWindow?.rootViewController?.view.removeFromSuperview()
        lockWindow?.rootViewController = nil
        lockWindow?.isHidden = true
        lockWindow?.windowScene = nil
    }

    private func hideLockView() {
        guard lockWindow != nil else { return }
        UIApplication.shared.windows.first?.makeKeyAndVisible()
        removeLockWindow()
    }

    private func handleAuthenticationStatus(_ authStyle: AuthenticationPresentationStyle?) {
        // dismiss
        guard let authStyle = authStyle else {
            localAuthVC?.dismiss(animated: true) { [unowned self] in
                localAuthVC = nil
            }
            return
        }
        localAuthVC?.dismiss(animated: false)
        let pincodeViewModel = PincodeViewModel(
            state: .check,
            isBackAvailable: !authStyle.options.contains(.required),
            successNotification: ""
        )
        localAuthVC = PincodeViewController(viewModel: pincodeViewModel)
        if authStyle.options.contains(.fullscreen) {
            localAuthVC?.modalPresentationStyle = .custom
        }

        var authSuccess = false
        pincodeViewModel.openMain.eraseToAnyPublisher()
            .sink { [weak self] _ in
                authSuccess = true
                self?.viewModel.authenticate(presentationStyle: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authStyle.completion?(false)
                }
            }
            .store(in: &subscriptions)
        pincodeViewModel.infoDidTap
            .sink(receiveValue: { [unowned self] in
                helpLauncher.launch()
            })
            .store(in: &subscriptions)
        localAuthVC?.onClose = { [weak self] in
            self?.viewModel.authenticate(presentationStyle: nil)
            if authSuccess == false {
                authStyle.onCancel?()
            }
        }
        presentLocalAuth()
    }

    private func presentLocalAuth() {
        hideLockView()
        let keyWindow = UIApplication.shared.windows.filter(\.isKeyWindow).first
        let topController = keyWindow?.rootViewController?.findLastPresentedViewController()
        if topController is UIAlertController {
            let presenting = topController?.presentingViewController
            topController?.dismiss(animated: false) { [weak presenting, weak localAuthVC] in
                guard let localAuthVC = localAuthVC else { return }
                presenting?.present(localAuthVC, animated: true)
            }
        } else {
            topController?.present(localAuthVC!, animated: true)
        }
    }

    // MARK: - Helpers

    private func setUpTabBarAppearance() {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.backgroundColor = Asset.Colors.snow.color
        standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: Asset.Colors.mountain.color,
        ]
        standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: Asset.Colors.night.color,
        ]
        standardAppearance.stackedLayoutAppearance.normal.iconColor = Asset.Colors.mountain.color
        standardAppearance.stackedLayoutAppearance.selected.iconColor = Asset.Colors.night.color
        standardAppearance.stackedItemPositioning = .automatic
        standardAppearance.shadowImage = nil
        standardAppearance.shadowColor = nil
        UITabBar.appearance().standardAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = standardAppearance
        }
    }
    
    private var viewWillAppearTriggered = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewWillAppearTriggered {
            viewModel.viewDidLoad.send()
            viewWillAppearTriggered = true
        }
    }

    private func bind() {
        // delay authentication status
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [unowned self] in
            self.viewModel.authenticationStatusPublisher
                .sink(receiveValue: { [weak self] in self?.handleAuthenticationStatus($0) })
                .store(in: &subscriptions)
        }

        viewModel.moveToHistory
            .sink(receiveValue: { [unowned self] in
                changeItem(to: .history)
            })
            .store(in: &subscriptions)

        viewModel.moveToIntercomSurvey
            .sink { id in
                guard !id.isEmpty else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    Intercom.presentSurvey(id)
                }
            }
            .store(in: &subscriptions)
        
        viewModel.moveToSendViaLinkClaim
            .sink { seed in
                guard !seed.isEmpty else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.showAlert(title: "Received sendViaLinkSeed", message: seed)
                }
            }
            .store(in: &subscriptions)

        // locking status
        viewModel.isLockedPublisher
            .sink(receiveValue: { [weak self] isLocked in
                isLocked ? self?.showLockView() : self?.hideLockView()
            })
            .store(in: &subscriptions)

        // blurEffectView
        viewModel.authenticationStatusPublisher
            .map { $0 == nil }
            .assign(to: \.isHidden, on: blurEffectView)
            .store(in: &subscriptions)
    }
}

// MARK: - UITabBarControllerDelegate

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard let selectedIndex = tabBarController.viewControllers?.firstIndex(of: viewController) else {
            return true
        }

        customTabBar.updateSelectedViewPositionIfNeeded()
        if TabItem(rawValue: selectedIndex) == .invest {
            if !available(.investSolendFeature) {
                if available(.jupiterSwapEnabled) {
                    jupiterSwapClickedSubject.send()
                } else {
                    analyticsManager.log(event: .mainSwap(isSellEnabled: sellDataService.isAvailable))
                }
            } else if !Defaults.isSolendTutorialShown, available(.solendDisablePlaceholder) {
                solendTutorialSubject.send()
                return false
            }
        }

        if TabItem(rawValue: selectedIndex) == .wallet,
           (viewController as! UINavigationController).viewControllers.count == 1,
           self.selectedIndex == selectedIndex
        {
            homeTabClickedTwicelySubject.send()
        }

        return true
    }
}

// MARK: - TabItem

private extension TabItem {
    var image: UIImage {
        switch self {
        case .wallet:
            return .tabBarSelectedWallet
        case .invest:
            return available(.investSolendFeature) ? .tabBarEarn : .tabBarSwap
        case .actions:
            return UIImage()
        case .history:
            return .tabBarHistory
        case .settings:
            return .tabBarSettings
        }
    }

    var displayTitle: String {
        switch self {
        case .wallet:
            return L10n.wallet
        case .invest:
            return available(.investSolendFeature) ? L10n.earn : L10n.swap
        case .actions:
            return ""
        case .history:
            return L10n.history
        case .settings:
            return L10n.settings
        }
    }
}

private extension UIViewController {
    /// Recursively find last presentedViewController
    /// - Returns: the last presented view controller
    func findLastPresentedViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.findLastPresentedViewController()
        }
        return self
    }
}
