import BankTransfer
import Combine
import Resolver
import KeyAppBusiness
import Foundation
import KeyAppKitCore
import SolanaSwift

public enum BankTransferClaimUserActionEvent: UserActionEvent {
    case track(BankTransferClaimUserAction, UserActionStatus)
    case sendFailure(String)
}

public class StrigaBankTransferUserActionConsumer: UserActionConsumer {
    public typealias Action = BankTransferClaimUserAction
    public typealias Event = BankTransferClaimUserActionEvent

    public let persistence: UserActionPersistentStorage
    let database: SynchronizedDatabase<String, Action> = .init()

    @Injected private var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>

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
            
            bankTransferService.value.repository.getAllWalletsByUser(userId: <#T##String#>)
            
            self?.handle(event: Event.track(action, .processing))
            // FIXME: - Real logic
            try? await Task.sleep(seconds: 2)
            self?.handle(event: Event.track(action, .ready))
        }
    }

    public func handle(event: any UserActionEvent) {
        guard let event = event as? Event else { return }
        handleInternalEvent(event: event)
    }

    func handleInternalEvent(event: Event) {
        switch event {
        case let .track(action, status):
            Task { [weak self] in
                guard let self = self else { return }
                let userAction = Action(
                    id: action.id,
                    challengeId: action.challengeId,
                    token: action.token,
                    amount: action.amount,
                    fromAddress: action.fromAddress,
                    receivingAddress: action.receivingAddress,
                    status: status
                )

                await self.database.set(for: userAction.id, userAction)
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

    public let challengeId: String
    public let token: Token?
    public let amount: String?
//    public let feeAmount: FeeAmount
    public let fromAddress: String
    public let receivingAddress: String

    /// Abstract status.
    public var status: UserActionStatus

    public var createdDate: Date
    public var updatedDate: Date

//    public init(id: String, status: UserActionStatus, createdDate: Date = Date(), updatedDate: Date = Date()) {
//        self.id = id
//        self.status = status
//        self.createdDate = createdDate
//        self.updatedDate = updatedDate
//    }

    public init(id: String, challengeId: String, token: Token?, amount: String?, fromAddress: String, receivingAddress: String, status: UserActionStatus, createdDate: Date = Date(), updatedDate: Date = Date()) {
        self.id = id
        self.challengeId = challengeId
        self.token = token
        self.amount = amount
        self.fromAddress = fromAddress
        self.receivingAddress = receivingAddress
        self.status = status
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }

    public static func == (lhs: BankTransferClaimUserAction, rhs: BankTransferClaimUserAction) -> Bool {
        lhs.id == rhs.id
    }
}

