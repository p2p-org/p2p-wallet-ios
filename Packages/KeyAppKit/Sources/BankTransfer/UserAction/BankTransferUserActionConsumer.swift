import Combine
import Resolver
import KeyAppBusiness
import Foundation
import KeyAppKitCore
import SolanaSwift

public enum BankTransferClaimUserActionEvent: UserActionEvent {
    case track(String, UserActionStatus)
    case sendFailure(String)
}

public class BankTransferUserActionConsumer: UserActionConsumer {
    public typealias Action = BankTransferClaimUserAction
    public typealias Event = BankTransferClaimUserActionEvent

    public let persistence: UserActionPersistentStorage
    let database: SynchronizedDatabase<String, Action> = .init()

    public init(persistence: UserActionPersistentStorage) {
        self.persistence = persistence
    }

    public var onUpdate: AnyPublisher<any UserAction, Never> {
        database
            .onUpdate
            .flatMap { data in
                Publishers.Sequence(sequence: Array(data.values))
            }
            .eraseToAnyPublisher()
    }

    public func start() {
        
    }

    public func process(action: any UserAction) {
        guard let action = action as? Action else { return }

        Task { [weak self] in
            await self?.database.set(for: action.id, action)

            let solanaAccountService: SolanaAccountsService = Resolver.resolve()
            let shouldMakeAccount = !(solanaAccountService.state.value.filter { account in
                account.data.token.address == PublicKey.usdcMint.base58EncodedString
            }.count > 0)
            
            self?.handle(event: Event.track(action.id, .pending))
            sleep(2)
            self?.handle(event: Event.track(action.id, .processing))
            sleep(2)
            self?.handle(event: Event.track(action.id, .ready))
        }
    }

    public func handle(event: any UserActionEvent) {
        guard let event = event as? Event else { return }
        handleInternalEvent(event: event)
    }

    func handleInternalEvent(event: Event) {
        switch event {
        case let .track(id, status):
            Task { [weak self] in
                guard let self = self else { return }

                let userAction = try? await Action(
                    id: id,
                    status: status,
                    updatedDate: Date()
                )

                if let userAction {
                    await self.database.set(for: userAction.id, userAction)
                }
            }
        case .sendFailure(let id):
            Task { [weak self] in
                guard var userAction = await self?.database.get(for: id) else { return }
                userAction.status = .error(UserActionError.networkFailure)
                await self?.database.set(for: id, userAction)
            }
        }
    }
}

public class BankTransferClaimUserAction: UserAction {
    /// Unique internal id to track.
    public var id: String

    /// Abstract status.
    public var status: UserActionStatus

    public var createdDate: Date
    public var updatedDate: Date

    public init(id: String, status: UserActionStatus, createdDate: Date = Date(), updatedDate: Date = Date()) {
        self.id = id
        self.status = status
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }

    public static func == (lhs: BankTransferClaimUserAction, rhs: BankTransferClaimUserAction) -> Bool {
        lhs.id == rhs.id
    }
}
