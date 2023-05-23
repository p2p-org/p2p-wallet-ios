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

    let solanaTokenService: SolanaTokensService

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
        solanaTokenService: SolanaTokensService,
        errorObserver: ErrorObserver,
        persistence: UserActionPersistentStorage
    ) {
        self.address = address
        self.signer = signer
        self.solanaClient = solanaClient
        self.wormholeAPI = wormholeAPI
        self.relayService = relayService
        self.solanaTokenService = solanaTokenService
        self.errorObserver = errorObserver
        self.persistence = persistence
    }

    public func start() {
        // Update bundle periodic
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.monitor()
        }

        // First fetch
        monitor()
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
                guard let self = self else { return }

                let userAction = try? await WormholeSendUserAction(
                    sendStatus: sendStatus,
                    solanaTokensService: self.solanaTokenService
                )

                if let userAction {
                    await self.database.set(for: userAction.id, userAction)
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
            await self?.database.set(for: action.id, action)

            /// Preparing transaction
            guard
                let transaction = action.transaction?.transaction,
                let data = Data(base64Encoded: transaction, options: .ignoreUnknownCharacters),
                var versionedTransaction = try? VersionedTransaction.deserialize(data: data),
                let configs = RequestConfiguration(encoding: "base64"),
                let signer = self?.signer
            else {
                let error = WormholeSendUserActionError.preparingTransactionFailure
                self?.errorObserver.handleError(
                    error,
                    userInfo: [WormholeClaimUserActionError.UserInfoKey.action.rawValue: action]
                )
                self?.handleInternalEvent(event: .sendFailure(message: action.id, error: error))
                return
            }

            do {
                // User signs transaction
                try versionedTransaction.sign(signers: [signer])

                // Relay service sign transacion
                // TODO: extract first n required signers for safety.
                let fullySignedTransaction = try await self?.relayService.signTransaction(
                    transactions: [versionedTransaction],
                    config: .init(operationType: .other)
                ).first

                guard let fullySignedTransaction else {
                    let error = WormholeSendUserActionError.feeRelaySignFailure
                    self?.errorObserver.handleError(
                        error,
                        userInfo: [WormholeClaimUserActionError.UserInfoKey.action.rawValue: action]
                    )
                    self?.handleInternalEvent(event: .sendFailure(message: action.id, error: error))
                    return
                }

                versionedTransaction = fullySignedTransaction

                // Submit transaction
                let encodedTrx = try versionedTransaction.serialize().base64EncodedString()
                _ = try await self?.solanaClient.sendTransaction(transaction: encodedTrx, configs: configs)
            } catch {
                self?.errorObserver.handleError(
                    error,
                    userInfo: [WormholeClaimUserActionError.UserInfoKey.action.rawValue: action]
                )
                let error = WormholeSendUserActionError.submittingToBlockchainFailure
                self?.handleInternalEvent(event: .sendFailure(message: action.id, error: error))
            }
        }
    }
}
