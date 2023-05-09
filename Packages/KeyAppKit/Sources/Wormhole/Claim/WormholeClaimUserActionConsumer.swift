//
//  File.swift
//
//
//  Created by Giang Long Tran on 05.04.2023.
//

import Combine
import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift

public class WormholeClaimUserActionConsumer: UserActionConsumer {
    public typealias Action = WormholeClaimUserAction

    public typealias Event = WormholeClaimUserActionEvent

    public typealias Error = WormholeClaimUserActionError

    /// Local table entity for persist user action.
    static let table = "WormholeSendClaimActionConsumer"

    // MARK: - Dependencies

    /// Wormhole API, the transaciton will be send through this API.
    let wormholeAPI: WormholeAPI

    /// Ethereum token repository. Will be used to reconstruct in-app token structure when getting status from wormhole
    /// API
    let ethereumTokenRepository: EthereumTokensRepository

    /// Persistence storage
    public let persistence: UserActionPersistentStorage

    /// Stream of updating user action.
    public var onUpdate: AnyPublisher<any UserAction, Never> {
        database
            .onUpdate
            .flatMap { data in Publishers.Sequence(sequence: Array(data.values)) }
            .eraseToAnyPublisher()
    }

    let errorObserver: ErrorObserver

    // MARK: - Variables

    /// User's Ethereum address
    let address: String?

    /// User's key pair for signing transaction.
    let signer: EthereumKeyPair?

    /// Internal database
    let database: SynchronizedDatabase<String, WormholeClaimUserAction> = .init()

    /// Peridoc timer
    var updateNewBundleTimer: Timer?

    // Only one task is allowed
    var fetchNewBundleTask: Task<Void, Swift.Error>?

    var subscriptions: [AnyCancellable] = []

    public init(
        address: String?,
        signer: EthereumKeyPair?,
        wormholeAPI: WormholeAPI,
        ethereumTokenRepository: EthereumTokensRepository,
        errorObserver: ErrorObserver,
        persistence: UserActionPersistentStorage
    ) {
        self.address = address
        self.signer = signer
        self.wormholeAPI = wormholeAPI
        self.ethereumTokenRepository = ethereumTokenRepository
        self.errorObserver = errorObserver
        self.persistence = persistence
    }

    public func start() {
        // Update bundle periodic
        updateNewBundleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.fetchNewBundle()
        }

        // First fetch
        fetchNewBundle()
    }

    deinit {
        updateNewBundleTimer?.invalidate()
    }

    public func handle(event: any UserActionEvent) {
        guard let event = event as? Event else { return }
        handleInternalEvent(event: event)
    }

    func handleInternalEvent(event: Event) {
        switch event {
        case .refresh:
            fetchNewBundle()

        case let .track(bundleStatus):
            Task { [weak self] in
                // Track new state
                guard let ethereumTokenRepository = self?.ethereumTokenRepository else { return }

                // Convert to Ethereum token.
                let token = try? await WormholeClaimUserActionHelper.extractEthereumToken(
                    tokenAmount: bundleStatus.resultAmount,
                    tokenRepository: ethereumTokenRepository
                )

                // Ensure token is handleable by client.
                guard let token else {
                    self?.errorObserver.handleError(Error.invalidToken)
                    return
                }

                let newStateUserAction = Action(bundleStatus: bundleStatus, token: token)
                await self?.database.set(for: newStateUserAction.bundleID, newStateUserAction)
            }

        case let .claimFailure(bundleID: bundleID, reason: reason):
            Task { [weak self] in
                guard var bundle = await self?.database.get(for: bundleID) else { return }
                bundle.internalState = .error(reason)
                await self?.database.set(for: bundleID, bundle)
            }

        case let .claimInProgress(bundleID: bundleID):
            Task { [weak self] in
                guard var bundle = await self?.database.get(for: bundleID) else { return }
                bundle.internalState = .processing
                await self?.database.set(for: bundleID, bundle)
            }
        }
    }

    public func process(action: any UserAction) {
        guard let action = action as? WormholeClaimUserAction else { return }

        Task { [weak self] in
            // Insert record into db.
            await self?.database.set(for: action.bundleID, action)

            // Prepare signing process
            guard let keyPair = self?.signer else {
                self?.handleInternalEvent(event: .claimFailure(bundleID: action.bundleID, reason: .signingFailure))
                return
            }

            guard case var .pending(rawBundle) = action.internalState else {
                let error = Error.claimFailure
                self?.handleInternalEvent(
                    event: .claimFailure(
                        bundleID: action.bundleID, reason: error
                    )
                )

                return
            }

            // Sign transaction with prepared key pair.
            do {
                try rawBundle.signBundle(with: keyPair)
            } catch {
                self?.handleInternalEvent(event: .claimFailure(bundleID: action.bundleID, reason: .signingFailure))
            }

            // Send transaction
            do {
                try await self?.wormholeAPI.sendEthereumBundle(bundle: rawBundle)
                self?.handleInternalEvent(event: .claimInProgress(bundleID: action.bundleID))
            } catch {
                self?.errorObserver.handleError(error)

                let error = Error.submitError

                self?.errorObserver.handleError(error)
                self?.handleInternalEvent(event: .claimFailure(bundleID: action.bundleID, reason: error))
            }
        }
    }
}
