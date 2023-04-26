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
import Wormhole

public class WormholeSendUserActionConsumer: UserActionConsumer {
    public typealias Action = WormholeSendUserAction

    public typealias Event = WormholeSendUserActionEvent

    public typealias Error = WormholeSendUserActionError

    static let table = "WormholeSendUserActionConsumer"

    /// User's solana address
    let address: String?

    /// User's key pair
    let signer: KeyPair?

    let solanaClient: SolanaAPIClient

    let wormholeAPI: WormholeAPI

    let relayService: RelayService

    let errorObserver: ErrorObserver

    public let persistence: UserActionPersistentStorage

    public var onUpdate: AnyPublisher<any UserAction, Never> {
        database
            .onUpdate
            .flatMap { data in
                Publishers.Sequence(sequence: Array(data.values))
            }
            .eraseToAnyPublisher()
    }

    let database: SynchronizedDatabase<String, Action> = .init()

    var subscriptions: [AnyCancellable] = []

    /// Peridoc timer
    var monitoringTimer: Timer?

    public init(
        address: String?,
        signer: KeyPair?,
        solanaClient: SolanaAPIClient,
        wormholeAPI: WormholeAPI,
        relayService: RelayService,
        errorObserver: ErrorObserver,
        persistence: UserActionPersistentStorage
    ) {
        self.address = address
        self.signer = signer
        self.solanaClient = solanaClient
        self.wormholeAPI = wormholeAPI
        self.relayService = relayService
        self.errorObserver = errorObserver
        self.persistence = persistence

        database
            .link(to: persistence, in: Self.table)
            .store(in: &subscriptions)
    }

    public func start() {
        Task {
            // Restore and filter
            try? await database.restore(from: self.persistence, table: Self.table) { _, userAction in
                switch userAction.status {
                case .pending:
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

                return true
            }

            // Update bundle periodic
            monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                self?.monitor()
            }

            // First fetch
            monitor()
        }
    }

    deinit {
        monitoringTimer?.invalidate()
    }

    public func handle(event: any UserActionEvent) {
        guard let event = event as? Event else { return }
        handleInternalEvent(event: event)
    }

    func handleInternalEvent(event: Event) {
        switch event {
        case let .track(sendStatus):
            Task { [weak self] in
                // Only update record
                if var userAction = await self?.database.get(for: sendStatus.message) {
                    switch userAction.status {
                    case .processing:
                        switch sendStatus.status {
                        case .pending, .inProgress:
                            return
                        case .completed:
                            userAction.status = .ready
                        case .canceled, .expired, .failed:
                            userAction.status = .error(Error.sendingFailure)
                        }
                    default:
                        return
                    }

                    await self?.database.set(for: userAction.message, userAction)
                }
            }

        case let .sendFailure(message: message, error: error):
            Task { [weak self] in
                guard var userAction = await self?.database.get(for: message) else { return }
                userAction.status = .error(error)
                await self?.database.set(for: message, userAction)
            }
        }
    }

    /// Prepare signing and sending to blockchain.
    public func process(action: any UserAction) {
        guard let action = action as? Action else { return }

        Task { [weak self] in
            await self?.database.set(for: action.message, action)

            /// Network fee in Solana network.
            let transactionFee: CryptoAmount = [action.fees.networkFee, action.fees.bridgeFee]
                .compactMap { $0 }
                .map(\.asCryptoAmount)
                .reduce(CryptoAmount(token: SolanaToken.nativeSolana), +)

            /// Account creation fee in Solana network.
            let accountCreationFee = action.fees.messageAccountRent?
                .asCryptoAmount ?? CryptoAmount(token: SolanaToken.nativeSolana)

            /// Preparing transaction
            guard
                let data = Data(base64Encoded: action.transaction.transaction, options: .ignoreUnknownCharacters),
                var versionedTransaction = try? VersionedTransaction.deserialize(data: data),
                let configs = RequestConfiguration(encoding: "base64"),
                let signer = self?.signer
            else {
                let error = WormholeSendUserActionError.preparingTransactionFailure
                self?.handleInternalEvent(event: .sendFailure(message: action.message, error: error))
                return
            }

            do {
                // User signs transaction
                try versionedTransaction.sign(signers: [signer])

                // Relay service sign transacion
                // TODO: extract first n required signers for safety.
                if versionedTransaction.message.value.staticAccountKeys.contains(action.relayContext.feePayerAddress) {
                    let fullySignedTransaction = try await self?.relayService.signTransaction(
                        transactions: [versionedTransaction],
                        config: .init(operationType: .other)
                    ).first

                    guard let fullySignedTransaction else {
                        let error = WormholeSendUserActionError.feeRelaySignFailure
                        self?.handleInternalEvent(event: .sendFailure(message: action.message, error: error))
                        return
                    }

                    versionedTransaction = fullySignedTransaction
                }

                // Submit transaction
                let encodedTrx = try versionedTransaction.serialize().base64EncodedString()
                _ = try await self?.solanaClient.sendTransaction(transaction: encodedTrx, configs: configs)
            } catch {
                self?.errorObserver.handleError(error)

                let error = WormholeSendUserActionError.submittingToBlockchainFailure
                self?.handleInternalEvent(event: .sendFailure(message: action.message, error: error))
            }
        }
    }
}
