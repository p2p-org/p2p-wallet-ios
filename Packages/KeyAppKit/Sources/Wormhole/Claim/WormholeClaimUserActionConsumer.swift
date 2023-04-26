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

        database
            .link(to: persistence, in: Self.table)
            .store(in: &subscriptions)
    }

    public func start() {
        Task {
            // Restore and filter some actions.
            try? await database.restore(from: self.persistence, table: Self.table) { _, userAction in
                switch userAction.internalState {
                case .pending:
                    // Never restore pending user action
                    return false
                case .processing:
                    // Remove if user action is live longer then 3 hours
                    if Date().timeIntervalSince(userAction.updatedDate) > 60 * 60 * 3 {
                        return false
                    }
                case .ready, .error:
                    // Remove if user action is live longer then 3 minutes
                    if Date().timeIntervalSince(userAction.updatedDate) > 60 * 3 {
                        return false
                    }
                }

                // Otherwise restore user action
                return true
            }

            manuallyCheck(userActions: await database.values())

            // Update bundle periodic
            updateNewBundleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                self?.fetchNewBundle()
            }

            // First fetch
            fetchNewBundle()
        }
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
                if var userAction = await self?.database.get(for: bundleStatus.bundleId) {
                    // Client side updating state
                    userAction.moveToNextStatus(nextStatus: bundleStatus.status)

                    // Update record
                    await self?.database.set(for: userAction.bundleID, userAction)
                } else {
                    // Track new pending claimings that wasn't initialed by user's device.
                    switch bundleStatus.status {
                    case .pending, .inProgress:
                        break
                    default:
                        return
                    }

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

                    let newTrackableUserAction = Action(bundleStatus: bundleStatus, token: token)
                    await self?.database.set(for: newTrackableUserAction.bundleID, newTrackableUserAction)
                }
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
