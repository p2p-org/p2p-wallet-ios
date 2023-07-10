import Combine
import Resolver
import KeyAppBusiness
import Foundation
import KeyAppKitCore
import SolanaSwift

public struct BankTransferClaimUserActionResult: Codable, Equatable {
    public let fromAddress: String
    public let challengeId: String
    public let token: Token
}

public enum BankTransferClaimUserActionEvent: UserActionEvent {
    case track(BankTransferClaimUserAction, UserActionStatus)
    case complete(BankTransferClaimUserAction, BankTransferClaimUserActionResult)
    case sendFailure(BankTransferClaimUserAction, String)
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

    public func start() {}

    public func process(action: any UserAction) {
        guard let action = action as? Action else { return }

        Task { [weak self] in
            await self?.database.set(for: action.id, action)
            self?.handle(event: Event.track(action, .processing))
            /// Checking if destination is in whitelist
            guard
                let service = self?.bankTransferService.value,
                let userId = await service.repository.getUserId(),
                let account = try await service.repository.getWallet(userId: userId)?.accounts.usdc,
                let amount = action.amount,
                let fromAddress = account.blockchainDepositAddress,
                let whitelistedAddressId = try await service.repository.whitelistIdFor(account: account) else {
                Logger.log(
                    event: "Striga Claim Action",
                    message: "Needs to whitelist account",
                    logLevel: .error
                )
                self?.handle(event: Event.sendFailure(action, "Needs to whitelist account"))
                return
            }

            let solanaAccountService: SolanaAccountsService = Resolver.resolve()
            let shouldMakeAccount = !(solanaAccountService.state.value.filter { account in
                account.data.token.address == PublicKey.usdcMint.base58EncodedString
            }.count > 0)

            do {
                let result = try await service.repository.initiateOnchainWithdrawal(
                    userId: userId,
                    sourceAccountId: account.accountID,
                    whitelistedAddressId: whitelistedAddressId,
                    amount: amount,
                    accountCreation: shouldMakeAccount
                )
                self?.handle(event: Event.complete(action, .init(
                    fromAddress: fromAddress,
                    challengeId: result.challengeId,
                    token: Token.usdc
                )))
            } catch {
                self?.handle(event: Event.sendFailure(action, error.localizedDescription))
            }
        }
    }

    public func handle(event: any UserActionEvent) {
        guard let event = event as? Event else { return }
        handleInternalEvent(event: event)
    }

    func handleInternalEvent(event: Event) {
        switch event {
        case let .complete(action, result):
            Task { [weak self] in
                guard let self = self else { return }
                var userAction = Action(
                    id: action.id,
                    accountId: action.accountId,
                    token: action.token,
                    amount: action.amount,
                    receivingAddress: action.receivingAddress,
                    status: .ready
                )
                userAction.result = result
                await self.database.set(for: userAction.id, userAction)
            }
        case let .track(action, status):
            Task { [weak self] in
                guard let self = self else { return }
                let userAction = Action(
                    id: action.id,
                    accountId: action.accountId,
                    token: action.token,
                    amount: action.amount,
                    receivingAddress: action.receivingAddress,
                    status: status
                )
                await self.database.set(for: userAction.id, userAction)
            }
        case .sendFailure(let action, _):
            Task { [weak self] in
                guard let userAction = await self?.database.get(for: action.id) else { return }
                userAction.status = .error(UserActionError.networkFailure)
                await self?.database.set(for: action.id, userAction)
            }
        }
    }
}

public class BankTransferClaimUserAction: UserAction {
    /// Unique internal id to track.
    public var id: String
    public var accountId: String
    public let token: EthereumToken?
    public let amount: String?
    public let receivingAddress: String
    /// Abstract status.
    public var status: UserActionStatus
    public var createdDate: Date
    public var updatedDate: Date
    public var result: BankTransferClaimUserActionResult?

    public init(
        id: String,
        accountId: String,
        token: EthereumToken?,
        amount: String?,
        receivingAddress: String,
        status: UserActionStatus,
        createdDate: Date = Date(),
        updatedDate: Date = Date()
    ) {
        self.id = id
        self.accountId = accountId
        self.token = token
        self.amount = amount
        self.receivingAddress = receivingAddress
        self.status = status
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }

    public static func == (lhs: BankTransferClaimUserAction, rhs: BankTransferClaimUserAction) -> Bool {
        lhs.id == rhs.id
    }
}