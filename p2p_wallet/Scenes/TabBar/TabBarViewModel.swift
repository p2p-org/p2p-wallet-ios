import Combine
import Foundation
import NameService
import Resolver
import SolanaSwift
import Deeplinking

final class TabBarViewModel {
    // Dependencies
    @Injected private var pricesService: PricesServiceType
    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var notificationService: NotificationService

    @Injected private var accountStorage: AccountStorageType
    @Injected private var nameService: NameService
    @Injected private var nameStorage: NameStorageType

    // Input
    let viewDidLoad = PassthroughSubject<Void, Never>()
    
    private let becomeActiveSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

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
        
        listenDidBecomeActiveForDeeplinks()
    }

    deinit {
        pricesService.stopObserving()
        debugPrint("\(String(describing: self)) deinited")
    }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        authenticationHandler.authenticate(presentationStyle: presentationStyle)
    }
    
    private func listenDidBecomeActiveForDeeplinks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.becomeActiveSubject.send()
        }
        
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink(receiveValue: { [weak self] _ in
                self?.becomeActiveSubject.send()
            })
            .store(in: &cancellables)
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

    var moveToIntercomSurvey: AnyPublisher<String, Never> {
        deeplinkingRoutePublisher
            .compactMap { route in
                switch route {
                case let .intercomSurvey(id):
                    return id
                default:
                    return nil
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    var moveToSendViaLinkClaim: AnyPublisher<URL, Never> {
        deeplinkingRoutePublisher
            .compactMap { route in
                switch route {
                case let .claimSentViaLink(url):
                    return url
                default:
                    return nil
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var isLockedPublisher: AnyPublisher<Bool, Never> { authenticationHandler.isLockedPublisher }
    
    // MARK: - Helpers

    private var deeplinkingRoutePublisher: AnyPublisher<Deeplinking.Route, Never> {
        Publishers.CombineLatest(
            authenticationStatusPublisher
                .filter { $0 == nil },
            becomeActiveSubject
        )
            .withLatestFrom (
                Resolver.resolve(DeeplinkingRouter.self)
                    .activeRoutePublisher
                    .filter { $0 != nil }
                    .map { $0! }
            )
            .debounce(for: .milliseconds(900), scheduler: RunLoop.main)
            .handleEvents(receiveOutput: { _ in
                Resolver.resolve(DeeplinkingRouter.self)
                    .markAsHandled()
            })
            .eraseToAnyPublisher()
    }
}
