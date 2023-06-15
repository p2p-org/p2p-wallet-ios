import Combine
import Foundation
import NameService
import Resolver
import SolanaSwift
import Deeplinking

final class TabBarViewModel {

    // MARK: - Dependencies

    @Injected private var pricesService: PricesServiceType
    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var notificationService: NotificationService

    @Injected private var accountStorage: AccountStorageType
    @Injected private var nameService: NameService
    @Injected private var nameStorage: NameStorageType

    // MARK: - Properties

    private var subscriptions = Set<AnyCancellable>()
    let viewDidLoad = PassthroughSubject<Void, Never>()
    
    // MARK: - Initializer

    init() {
        pricesService.startObserving()

        // Name service
        Task {
            guard let account = accountStorage.account else { return }
            let name: String = try await nameService.getName(account.publicKey.base58EncodedString, withTLD: true) ?? ""
            nameStorage.save(name: name)
        }

        // Notification
        notificationService.requestRemoteNotificationPermission()
    }

    deinit {
        pricesService.stopObserving()
        debugPrint("\(String(describing: self)) deinited")
    }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        authenticationHandler.authenticate(presentationStyle: presentationStyle)
    }
}

// MARK: - Output

extension TabBarViewModel {
    var authenticationStatusPublisher: AnyPublisher<AuthenticationPresentationStyle?, Never> {
        authenticationHandler.authenticationStatusPublisher
    }

    // TODO: - Deeplink for history
    var moveToHistory: AnyPublisher<Void, Never> {
        Publishers.Merge(
            notificationService.showNotification
                .filter { $0 == .history }
                .map { _ in () },
            viewDidLoad
                .filter { [weak self] in
                    self?.notificationService.showFromLaunch == true
                }
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.notificationService.notificationWasOpened()
                })
        )
        .map { _ in () }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    var deeplinkingRoutePublisher: AnyPublisher<Deeplinking.Route, Never> {
        // Observe appDidBecomeActive
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .map { _ in () }
            // fill first event as first time opening app the appDidBecomeActive
            // will not be called
            .prepend(())
            // wait for latest from authenticationStatus
            .flatMap { [unowned self] in
                authenticationStatusPublisher
                    .filter { $0 == nil }
            }
            // get latest route
            .withLatestFrom(
                Resolver.resolve(DeeplinkingRouter.self)
                    .activeRoutePublisher
                    .print("UIN.DeeplinkingRouter")
            )
            // delay to wait for authentication to be closed
            .delay(for: .milliseconds(800), scheduler: RunLoop.main)
            // mark as handled after completion
            .handleEvents(receiveOutput: { _ in
                Resolver.resolve(DeeplinkingRouter.self)
                    .markAsHandled()
            })
            // receive on main
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var isLockedPublisher: AnyPublisher<Bool, Never> {
        authenticationHandler.isLockedPublisher
    }
}
