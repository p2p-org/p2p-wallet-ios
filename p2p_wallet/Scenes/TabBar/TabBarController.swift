//
//  TabBarController.swift
//  p2p_wallet
//
//  Created by Ivan on 09.07.2022.
//

import Combine
import KeyAppUI
import Resolver
import SwiftUI
import UIKit
import RxSwift
import RxCocoa

final class TabBarController: UITabBarController {
    // MARK: - Dependencies

    @Injected private var helpLauncher: HelpCenterLauncher
    @Injected private var solanaTracker: SolanaTracker

    // MARK: - Publishers
    var middleButtonClicked: AnyPublisher<Void, Never> { customTabBar.middleButtonClicked }
    private let homeTabClickedTwicelySubject = PassthroughSubject<Void, Never>()
    var homeTabClickedTwicely: AnyPublisher<Void, Never> { homeTabClickedTwicelySubject.eraseToAnyPublisher() }
    private let solendTutorialSubject = PassthroughSubject<Void, Never>()
    var solendTutorialClicked: AnyPublisher<Void, Never> { solendTutorialSubject.eraseToAnyPublisher() }

    // MARK: - Properties
    private let viewModel: TabBarViewModel
    private let authenticateWhenAppears: Bool
    
    private let disposeBag = DisposeBag()
    private var subscriptions = Set<AnyCancellable>()

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

    private func showLockView() {
        UIApplication.shared.kWindow?.endEditing(true)
        let lockView = LockView()
        UIApplication.shared.windows.last?.addSubview(lockView)
        lockView.autoPinEdgesToSuperviewEdges()
        solanaTracker.stopTracking()
    }

    private func hideLockView() {
        for view in UIApplication.shared.windows.last?.subviews ?? [] where view is LockView {
            view.removeFromSuperview()
        }
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
            localAuthVC?.modalPresentationStyle = .fullScreen
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

    private func bind() {
        rx.viewWillAppear
            .take(1)
            .mapToVoid()
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: disposeBag)

        // delay authentication status
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [unowned self] in
            self.viewModel.authenticationStatusDriver
                .drive(onNext: { [weak self] in self?.handleAuthenticationStatus($0) })
                .disposed(by: disposeBag)
        }

        viewModel.moveToHistory
            .drive(onNext: { [unowned self] in
                if available(.investSolendFeature) {
                    changeItem(to: .history)
                } else {
                    // old position of history tab controller
                    changeItem(to: .invest)
                }
            })
            .disposed(by: disposeBag)
        // locking status
        viewModel.isLockedDriver
            .drive(onNext: { [weak self] isLocked in
                isLocked ? self?.showLockView() : self?.hideLockView()
            })
            .disposed(by: disposeBag)

        // blurEffectView
        viewModel.authenticationStatusDriver
            .map { $0 == nil }
            .drive(blurEffectView.rx.isHidden)
            .disposed(by: disposeBag)
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
        
        let array = [1]
        let _ = array[1]

        if TabItem(rawValue: selectedIndex) == .history, !available(.investSolendFeature) {
            helpLauncher.launch()
            return false
        }
        customTabBar.updateSelectedViewPositionIfNeeded()
        if TabItem(rawValue: selectedIndex) == .invest {
            if available(.investSolendFeature), !Defaults.isSolendTutorialShown, available(.solendDisablePlaceholder) {
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
            return available(.investSolendFeature) ? .tabBarEarn : .tabBarHistory
        case .actions:
            return UIImage()
        case .history:
            return available(.investSolendFeature) ? .tabBarHistory : .tabBarFeedback
        case .settings:
            return .tabBarSettings
        }
    }

    var displayTitle: String {
        switch self {
        case .wallet:
            return L10n.wallet
        case .invest:
            return available(.investSolendFeature) ? L10n.earn : L10n.history
        case .actions:
            return ""
        case .history:
            return available(.investSolendFeature) ? L10n.history : L10n.feedback
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
