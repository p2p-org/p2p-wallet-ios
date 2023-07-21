import Combine
import Wormhole
import Foundation
import NameService
import Resolver
import SolanaSwift
import KeyAppBusiness
import KeyAppKitCore
import UIKit

final class TabBarViewModel {
    
    // MARK: - Dependencies
    
    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var notificationService: NotificationService

    @Injected private var accountStorage: SolanaAccountStorage
    @Injected private var nameService: NameService
    @Injected private var nameStorage: NameStorageType
    
    @Injected private var userActionService: UserActionService
    @Injected private var ethereumAccountsService: EthereumAccountsService
    @Injected private var solanaAccountsService: SolanaAccountsService

    // Input
    let viewDidLoad = PassthroughSubject<Void, Never>()

    private let becomeActiveSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private let ethereumAggregator = CryptoEthereumAccountsAggregator()

    init() {
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
        Publishers.Merge(
            authenticationHandler
                .isLockedPublisher
                .filter { value in
                    GlobalAppState.shared.surveyID != nil && value == false
                }
                .map { _ in () },

            viewDidLoad
                .filter { [weak self] in
                    self?.notificationService.showFromLaunch == true
                }
        )
        .map { _ in () }
        .map {
            GlobalAppState.shared.surveyID ?? ""
        }
        .handleEvents(receiveOutput: { _ in
            GlobalAppState.shared.surveyID = nil
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    var moveToSendViaLinkClaim: AnyPublisher<URL, Never> {
        Publishers.CombineLatest(
            authenticationStatusPublisher,
            becomeActiveSubject
        )
        .debounce(for: .milliseconds(900), scheduler: RunLoop.main)
        .filter { $0.0 == nil }
        .compactMap { _ in GlobalAppState.shared.sendViaLinkUrl }
        .handleEvents(receiveOutput: { _ in
            GlobalAppState.shared.sendViaLinkUrl = nil
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    var isLockedPublisher: AnyPublisher<Bool, Never> { authenticationHandler.isLockedPublisher }
    
    var transferAccountsPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            ethereumAccountsService.statePublisher,
            userActionService.$actions.map { userActions in
                userActions.compactMap { $0 as? WormholeClaimUserAction }
            }
        )
        .map { state, actions in
            let ethAccounts = self.ethereumAggregator.transform(input: (state.value, actions))
            let transferAccounts = ethAccounts.filter { ethAccount in
                switch ethAccount.status {
                case .readyToClaim, .isClaiming:
                    return true
                default:
                    return false
                }
            }
            return !transferAccounts.isEmpty
        }
        .eraseToAnyPublisher()
    }
    
    var walletBalancePublisher: AnyPublisher<String, Never> {
        solanaAccountsService.statePublisher
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                let equityValue: Double = state.value.reduce(0) { $0 + $1.amountInFiatDouble }
                return "\(Defaults.fiat.symbol)\(equityValue.formattedForWallet())"
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
