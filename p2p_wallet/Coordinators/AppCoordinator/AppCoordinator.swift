import AnalyticsManager
import Combine
import Foundation
import KeyAppUI
import Onboarding
import OrcaSwapSwift
import Resolver
import Sell
import Sentry
import SolanaSwift
import UIKit

final class AppCoordinator: Coordinator<Void> {
    // MARK: - Dependencies

    private var appEventHandler: AppEventHandlerType = Resolver.resolve()
    private let storage: AccountStorageType & PincodeStorageType & NameStorageType = Resolver.resolve()
    let analyticsManager: AnalyticsManager = Resolver.resolve()
    let notificationsService: NotificationService = Resolver.resolve()

    @Injected var notificationService: NotificationService
    @Injected var userWalletManager: UserWalletManager
    @Injected var createNameService: CreateNameService

    // MARK: - Properties

    let window: UIWindow
    var showAuthenticationOnMainOnAppear = true

    var reloadEvent = PassthroughSubject<Void, Never>()

    // MARK: - Initializers

    init(window: UIWindow) {
        self.window = window
        super.init()
        defer { appEventHandler.delegate = self }
        bind()
    }

    // MARK: - Methods

    enum AppCoordinatorEvent {
        case onboarding
        case createUsername
        case wallet(UserWallet)
    }

    private var eventHandler = PassthroughSubject<AppCoordinatorEvent, Never>()

    /// Starting point for coordinator
    override func start() -> AnyPublisher<Void, Never> {
        // set appearance
        window.overrideUserInterfaceStyle = Defaults.appearance

        // 1. Opening splash
        let vc = BaseVC()
        let lockView = LockView()
        vc.view.addSubview(lockView)
        lockView.autoPinEdgesToSuperviewEdges()
        window.rootViewController = vc
        window.makeKeyAndVisible()

        userWalletManager.$wallet
            .dropFirst()
            .combineLatest(
                reloadEvent.map { _ in }.prepend(())
            )
            .handleEvents(receiveOutput: { wallet, _ in
                self.sendUserIdentifierToAnalyticsProviders(wallet)
            })
            .map { wallet, _ in
                if let wallet {
                    return AppCoordinatorEvent.wallet(wallet)
                } else {
                    return AppCoordinatorEvent.onboarding
                }
            }.sink(receiveValue: {  [unowned self] event in
                self.eventHandler.send(event)
            }).store(in: &subscriptions)

        // infinite handler
        return eventHandler
            .receive(on: RunLoop.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                Task {
                    await Resolver.resolve(WarmupManager.self).start()
                    try await self?.userWalletManager.refresh()
                }
            })
            .flatMap({ [unowned self] event in
                switch event {
                case .onboarding:
                    return self.navigateToOnboardingFlow()
                case .createUsername:
                    return self.coordinate(to: CreateUsernameCoordinator(navigationOption: .onboarding(window: self.window)))
                        .withLatestFrom(self.userWalletManager.$wallet)
                        .compactMap { $0 }
                        .handleEvents(receiveOutput: { wallet in
                            self.eventHandler.send(.wallet(wallet))
                        })
                        .map { _ in Void() }
                        .eraseToAnyPublisher()
                case .wallet(_):
                    return self.navigateToMain(window: self.window)
                        .handleEvents(receiveSubscription: { [weak self] _ in
                            self?.warmUpMain()
                        })
                        .eraseToAnyPublisher()
                }
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Navigation

    /// Navigate to Main scene
    private func navigateToMain(window: UIWindow) -> AnyPublisher<Void, Never> {
        let coordinator = TabBarCoordinator(
            window: window,
            authenticateWhenAppears: showAuthenticationOnMainOnAppear
        )
        return coordinate(to: coordinator)
    }

    /// Navigate to onboarding flow if user is not yet created
    private func navigateToOnboardingFlow() -> AnyPublisher<Void, Never> {
        let provider = Resolver.resolve(StartOnboardingNavigationProvider.self)
        let startCoordinator = provider.startCoordinator(for: window)

        return coordinate(to: startCoordinator)
            .asyncMap { [unowned self] result -> AppCoordinatorEvent in
                GlobalAppState.shared.shouldPlayAnimationOnHome = true
                showAuthenticationOnMainOnAppear = false
                let userWalletManager: UserWalletManager = Resolver.resolve()
                switch result {
                case let .created(data):

                    analyticsManager.log(event: .setupOpen(fromPage: "create_wallet"))
                    analyticsManager.log(event: .createConfirmPin(result: true))

                    saveSecurity(data: data.security)
                    // Setup user wallet
                    do {
                        try await userWalletManager.add(
                            seedPhrase: data.wallet.seedPhrase.components(separatedBy: " "),
                            derivablePath: data.wallet.derivablePath,
                            name: nil,
                            deviceShare: data.deviceShare,
                            ethAddress: data.ethAddress
                        )
                    } catch {
                        fatalError("Wallet must be")
                    }
                    guard let wallet = userWalletManager.wallet else {
                        fatalError("Wallet must be")
                    }
                    return available(.onboardingUsernameEnabled) ? AppCoordinatorEvent.createUsername : .wallet(wallet)
                case let .restored(data):
                    analyticsManager.log(event: .restoreConfirmPin(result: true))

                    let restoreMethod: String = data.metadata == nil ? "seed" : "web3auth"
                    analyticsManager.log(parameter: .userRestoreMethod(restoreMethod))

                    saveSecurity(data: data.security)
                    // Setup user wallet
                    do {
                        try await userWalletManager.add(
                            seedPhrase: data.wallet.seedPhrase.components(separatedBy: " "),
                            derivablePath: data.wallet.derivablePath,
                            name: nil,
                            deviceShare: nil,
                            ethAddress: data.ethAddress
                        )
                    } catch {
                        fatalError("Wallet must be")
                    }
                    guard let wallet = userWalletManager.wallet else {
                        fatalError("Wallet must be")
                    }
                    return AppCoordinatorEvent.wallet(wallet)
                case .breakProcess:
                    return .onboarding
                }
            }
            .handleEvents(receiveOutput: { [weak self] result in
                self?.eventHandler.send(result)
            })
            .map { _ in }.eraseToAnyPublisher()
    }

    // MARK: - Helper

    private func warmUpMain() {
        Task.detached {
            await Resolver.resolve(WalletMetadataService.self).synchronize()
        }

        Task {
            try await Resolver.resolve(OrcaSwapType.self).load()
        }

        Task {
            await Resolver.resolve(JupiterTokensRepository.self).load()
        }

        Task {
            // load services
            if available(.sellScenarioEnabled) {
                await Resolver.resolve((any SellDataService).self).checkAvailability()
            }
        }
    }

    private func sendUserIdentifierToAnalyticsProviders(_ wallet: UserWallet?) {
        // Amplitude
        let amplitudeAnalyticsProvider: AmplitudeAnalyticsProvider = Resolver.resolve()
        amplitudeAnalyticsProvider.setUserId(wallet?.account.publicKey.base58EncodedString)

        // Sentry
        if let wallet {
            var sentryUser = Sentry.User(
                userId: wallet.account.publicKey.base58EncodedString
            )
            sentryUser.username = wallet.name
            SentrySDK.setUser(sentryUser)
        } else {
            SentrySDK.setUser(nil)
        }
    }

    private func saveSecurity(data: SecurityData) {
        Resolver.resolve(PincodeStorageType.self).save(data.pincode)
        Defaults.isBiometryEnabled = data.isBiometryEnabled
    }

    private func hideLoadingAndTransitionTo(_ vc: UIViewController) {
        window.rootViewController?.view.hideLoadingIndicatorView()
        window.animate(newRootViewController: vc)
    }

    private func bind() {
        createNameService.createNameResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSuccess in
                if isSuccess {
                    guard let view = self?.window.rootViewController?.view else { return }
                    SnackBar(title: "🎉", icon: nil, text: L10n.nameWasBooked).show(in: view)
                } else {
                    self?.notificationService.showDefaultErrorNotification()
                }
            }.store(in: &subscriptions)
    }
}
