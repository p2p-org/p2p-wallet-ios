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
            // Restore
            try? await database.restore(from: self.persistence, table: Self.table)

            // Revalidate old bundle.
            for userAction in await database.values() {
                switch userAction.status {
                case .pending, .processing:
                    break
                case .ready, .error:
                    // Remove if user action is live longer then 3 minutes
                    if Date().timeIntervalSince(userAction.updatedDate) > 60 * 3 {
                        await database.remove(key: userAction.bundleID)
                    }
                }
            }

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

    public func fetchNewBundle() {
        Task { [weak self] in
            do {
                guard let address = self?.address else { return }

                let bundles: [WormholeBundleStatus]? = try await self?
                    .wormholeAPI
                    .listEthereumBundles(userWallet: address)

                guard let bundles else { return }

                for bundle in bundles {
                    self?.handleEvent(event: .trackNewBundle(bundle))
                }
            } catch {
                self?.errorObserver.handleError(error)
            }
        }
    }

    public func handleEvent(event: Event) {
        switch event {
        case let .trackNewBundle(bundleStatus):
            Task { [weak self] in
                if var userAction = await self?.database.get(for: bundleStatus.bundleId) {
                    // Update processing to ready or error.
                    switch userAction.status {
                    case .processing:
                        switch bundleStatus.status {
                        case .completed:
                            userAction.status = .ready
                        case .failed, .expired, .canceled:
                            userAction.status = .error(Error.claimingFinishesWithError)
                        default:
                            return
                        }
                    default:
                        return
                    }
                    
                    // Update record
                    await self?.database.set(for: userAction.bundleID, userAction)
                } else {
                    // Only track new pending claimings
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
                bundle.status = .error(reason)
                await self?.database.set(for: bundleID, bundle)
            }

        case let .claimInProgress(bundleID: bundleID):
            Task { [weak self] in
                guard var bundle = await self?.database.get(for: bundleID) else { return }
                bundle.status = .pending
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
                self?.handleEvent(event: .claimFailure(bundleID: action.bundleID, reason: .signingFailure))
                return
            }

            // Expect bundle for sending
            guard case var .bundle(rawBundle) = action.bundle else {
                self?.handleEvent(event: .claimFailure(bundleID: action.bundleID, reason: .signingFailure))
                return
            }

            // Sign transaction with prepared key pair.
            do {
                try rawBundle.signBundle(with: keyPair)
            } catch {
                self?.handleEvent(event: .claimFailure(bundleID: action.bundleID, reason: .signingFailure))
            }

            // Send transaction
            do {
                try await self?.wormholeAPI.sendEthereumBundle(bundle: rawBundle)
                self?.handleEvent(event: .claimInProgress(bundleID: action.bundleID))
            } catch {
                self?.errorObserver.handleError(error)

                let error = Error.submitError

                self?.errorObserver.handleError(error)
                self?.handleEvent(event: .claimFailure(bundleID: action.bundleID, reason: error))
            }
        }
    }
}
