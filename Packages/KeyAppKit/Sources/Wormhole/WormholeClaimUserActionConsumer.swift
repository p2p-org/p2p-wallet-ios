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

actor SynchronizedSet<T: Hashable> {
    private var data: Set<T> = []

    func insert(_ element: T) async {
        data.insert(element)
    }

    func getData() async -> Set<T> {
        data
    }

    func tryInsert(_ element: T) async -> Bool {
        if data.contains(element) {
            return false
        } else {
            data.insert(element)
            return true
        }
    }

    func tryInsert(_ elements: Set<T>) async -> Bool {
        if data.intersection(elements).isEmpty {
            data.formUnion(elements)
            return true
        } else {
            return false
        }
    }

    func delete(_ elements: Set<T>) async {
        data.subtract(elements)
    }
}

public class WormholeClaimUserActionConsumer: UserActionConsumer {
    public typealias Action = WormholeClaimUserAction

    static let table = "WormholeSendClaimActionConsumer"

    let signer: () -> EthereumKeyPair?

    let wormholeAPI: WormholeAPI

    let ethereumTokenRepository: EthereumTokensRepository

    let errorObserver: ErrorObserver

    public let persistence: UserActionPersistentStorage

    public let onUpdate: PassthroughSubject<UserAction, Never> = .init()

    var observedBundleIDs: SynchronizedSet<String> = .init()

    var updateNewBundleTimer: Timer?

    var tasks: [Task<Void, Never>] = []

    public init(
        signer: @escaping () -> EthereumKeyPair?,
        wormholeAPI: WormholeAPI,
        ethereumTokenRepository: EthereumTokensRepository,
        errorObserver: ErrorObserver,
        persistence: UserActionPersistentStorage
    ) {
        self.signer = signer
        self.wormholeAPI = wormholeAPI
        self.ethereumTokenRepository = ethereumTokenRepository
        self.errorObserver = errorObserver
        self.persistence = persistence
    }

    public func start() {
//        // Restore last running.
//        Task {
//            do {
//                let userActions: [Action] = try await persistence.query(in: Self.table, type: Action.self)
//                for userAction in userActions {
//                    self.process(action: userAction)
//                }
//            } catch {
//                errorObserver.handleError(error)
//            }
//        }

        // Update bundle
        updateNewBundleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.fetchNewBundle()
        }

        fetchNewBundle()
    }

    deinit {
        updateNewBundleTimer?.invalidate()
    }

    public func fetchNewBundle() {
        Task {
            guard let keyPair = signer() else {
                return
            }

            do {
                let runningBundles = try await wormholeAPI.listEthereumBundles(userWallet: keyPair.address)

                for runningBundle in runningBundles {
                    let token: EthereumToken

                    switch runningBundle.resultAmount.token {
                    case let .ethereum(contract):
                        if let contract {
                            token = try await ethereumTokenRepository.resolve(address: contract)
                        } else {
                            token = EthereumToken()
                        }
                    default:
                        errorObserver.handleError(
                            UserActionError(
                                domain: "WormholeClaimUserActionConsumer",
                                code: 3,
                                reason: "Unexpected token"
                            )
                        )
                        continue
                    }

                    let action = Action(bundleStatus: runningBundle, token: token)
                    self.process(action: action)
                }
            } catch {
                errorObserver.handleError(error)
            }
        }
    }

    public func process(action: UserAction) {
        let task = Task {
            guard var action = action as? Action else { return }
            guard await observedBundleIDs.tryInsert(action.trackingKey) else { return }

            var running = true
            while running, !Task.isCancelled {
                // Emit changes
                onUpdate.send(action)

                switch action.status {
                case .pending:
                    action = await onPending(action: action)

                case .processing:
                    action = await onProcessing(action: action)

                case .ready:
                    await observedBundleIDs.delete(action.trackingKey)
                    running = false

                case let .error(error):
                    errorObserver.handleError(error)
                    await observedBundleIDs.delete(action.trackingKey)
                    running = false
                }

//                // Report error
//                switch action.status {
//                case let .error(error):
//                    errorObserver.handleError(error)
//                default:
//                    break
//                }

                if Task.isCancelled {
                    return
                }

//                // Save state
//                do {
//                    switch action.status {
//                    case .ready, .error:
//                        if Date().timeIntervalSince(action.createdDate) > 60 * 2 {
//                            try await persistence.delete(in: Self.table, userAction: action)
//                        } else {
//                            try await persistence.insert(in: Self.table, userAction: action)
//                        }
//                    default:
//                        try await persistence.insert(in: Self.table, userAction: action)
//                    }
//                } catch {
//                    errorObserver.handleError(error)
//                }

                // Emit changes
                onUpdate.send(action)
            }
        }

        tasks.append(task)
    }

    /// Prepare signing and sending to blockchain.
    func onPending(action: Action) async -> Action {
        var action = action

        defer {
            action.updatedDate = Date()
        }

        guard let keyPair = signer() else {
            action.status = .error(.signingFailure)
            return action
        }

        guard case var .bundle(rawBundle) = action.bundle else {
            action.status = .error(.signingFailure)
            return action
        }

        do {
            try rawBundle.signBundle(with: keyPair)
        } catch {
            action.status = .error(.signingFailure)
            return action
        }

        do {
            try await wormholeAPI.sendEthereumBundle(bundle: rawBundle)
            action.bundle = .bundle(rawBundle)
            action.status = .processing
        } catch {
            errorObserver.handleError(error)
            action
                .status =
                .error(.init(domain: "WormholeClaimUserActionConsumer", code: 1,
                             reason: "Sending Ethereum bundle returns with error"))
            return action
        }

        return action
    }

    func onProcessing(action: Action) async -> Action {
        var action = action

        do {
            let bundleStatus = try await wormholeAPI.getEthereumBundleStatus(bundleID: action.bundleID)

            switch bundleStatus.status {
            case .failed:
                action
                    .status =
                    .error(.init(domain: "WormholeClaimUserActionConsumer", code: 2, reason: "Claiming failure"))

            case .pending:
                try await Task.sleep(seconds: 10)

            case .expired:
                action
                    .status =
                    .error(.init(domain: "WormholeClaimUserActionConsumer", code: 2, reason: "Claiming is expired"))
            case .canceled:
                action
                    .status =
                    .error(.init(domain: "WormholeClaimUserActionConsumer", code: 2,
                                 reason: "Claiming was canceled"))
            case .inProgress:
                try await Task.sleep(seconds: 10)
            case .completed:
                action.status = .ready
            }
        } catch {
            errorObserver.handleError(error)
        }

        return action
    }
}
