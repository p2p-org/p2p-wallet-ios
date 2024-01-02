import AnalyticsManager
import Combine
import Onboarding
import Resolver
import Sell
import SwiftUI
import UIKit

final class TabBarController: UITabBarController {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var solanaTracker: SolanaTracker
    @Injected private var deviceShareMigration: DeviceShareMigrationService

    // MARK: - Publishers

    private let homeTabClickedTwicelySubject = PassthroughSubject<Void, Never>()
    var homeTabClickedTwicely: AnyPublisher<Void, Never> { homeTabClickedTwicelySubject.eraseToAnyPublisher() }
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
            viewControllers?[index].tabBarItem = UITabBarItem(
                title: item.displayTitle,
                image: item.image != nil ? .init(resource: item.image!) : nil,
                selectedImage: item.image != nil ? .init(resource: item.image!) : nil
            )
        }

        deviceShareMigration
            .isMigrationAvailablePublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] migrationIsAvailable in
                if migrationIsAvailable {
                    self?.viewControllers?[TabItem.settings.rawValue].tabBarItem
                        .image = .init(resource: .tabBarSettingsWithAlert)
                    self?.viewControllers?[TabItem.settings.rawValue].tabBarItem
                        .selectedImage = .init(resource: .selectedTabBarSettingsWithAlert)
                } else {
                    self?.viewControllers?[TabItem.settings.rawValue].tabBarItem
                        .image = .init(resource: .tabBarSettings)
                    self?.viewControllers?[TabItem.settings.rawValue].tabBarItem
                        .selectedImage = .init(resource: .tabBarSettings)
                }
            }
            .store(in: &subscriptions)
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
            viewModel.authenticate(presentationStyle: .login())
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
        standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont.font(of: .label1, weight: .regular),
            .foregroundColor: UIColor(resource: .mountain),
        ]
        standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont.font(of: .label1, weight: .regular),
            .foregroundColor: UIColor(resource: .night),
        ]
        standardAppearance.stackedLayoutAppearance.normal.iconColor = .init(resource: .mountain)
        standardAppearance.stackedLayoutAppearance.selected.iconColor = .init(resource: .night)
        standardAppearance.stackedItemPositioning = .automatic
        UITabBar.appearance().standardAppearance = standardAppearance
        UITabBar.appearance().scrollEdgeAppearance = standardAppearance

        tabBar.isTranslucent = true
        tabBar.backgroundColor = .clear
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

        // locking status
        viewModel.isLockedPublisher
            .sink(receiveValue: { [weak self] isLocked in
                isLocked ? self?.showLockView() : self?.hideLockView()
            })
            .store(in: &subscriptions)

        // blurEffectView
        viewModel.authenticationStatusPublisher
            .map { $0 == nil }
            .assignWeak(to: \.isHidden, on: blurEffectView)
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

        if let tabItem = TabItem(rawValue: selectedIndex) {
            switch tabItem {
            case .wallet:
                viewModel.cryptoTapped()

                if (viewController as! UINavigationController).viewControllers.count == 1,
                   self.selectedIndex == selectedIndex
                {
                    homeTabClickedTwicelySubject.send()
                }
            case .swap:
                viewModel.swapTapped()
            case .history:
                viewModel.historyTapped()
            case .settings:
                viewModel.settingsTapped()
            }
        }

        customTabBar.updateSelectedViewPositionIfNeeded()

        return true
    }
}

// MARK: - TabItem

private extension TabItem {
    var image: ImageResource? {
        switch self {
        case .wallet:
            return .tabBarCrypto
        case .swap:
            return .tabBarSwap
        case .history:
            return .tabBarHistory
        case .settings:
            return .tabBarSettings
        }
    }

    var displayTitle: String {
        switch self {
        case .wallet:
            return L10n.crypto
        case .swap:
            return L10n.swap
        case .history:
            return L10n.history
        case .settings:
            return L10n.settings
        }
    }

    var analyticsEvent: AnalyticsEvent? {
        switch self {
        case .wallet:
            return KeyAppAnalyticsEvent.mainWallet
        case .history:
            return KeyAppAnalyticsEvent.mainHistory
        case .settings:
            return KeyAppAnalyticsEvent.mainSettings
        default:
            return nil
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
