import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift

public enum OutgoingBankTransferUserActionResult: Codable, Equatable {
    case requestWithdrawInfo(receiver: String)
    case initiated(challengeId: String, IBAN: String, BIC: String)
}

public enum OutgoingBankTransferUserActionEvent: UserActionEvent {
    case track(OutgoingBankTransferUserAction, UserActionStatus)
    case complete(OutgoingBankTransferUserAction, OutgoingBankTransferUserActionResult)
    case sendFailure(OutgoingBankTransferUserAction, String)
}

public class StrigaBankTransferOutgoingUserActionConsumer: UserActionConsumer {
    public typealias Action = OutgoingBankTransferUserAction
    public typealias Event = OutgoingBankTransferUserActionEvent

    public let persistence: UserActionPersistentStorage
    let database: SynchronizedDatabase<String, Action> = .init()

    private var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>

    public init(
        persistence: UserActionPersistentStorage,
        bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>
    ) {
        self.persistence = persistence
        self.bankTransferService = bankTransferService
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
            /// Checking if all data is available
            guard
                let service = self?.bankTransferService.value,
                let userId = await service.repository.getUserId(),
                let withdrawInfo = try? await service.repository.getWithdrawalInfo(userId: userId),
                let iban = withdrawInfo.IBAN,
                let bic = withdrawInfo.BIC
            else {
                Logger.log(
                    event: "Striga Confirm Action",
                    message: "Absence of data",
                    logLevel: .error
                )
                let regData = try? await self?.bankTransferService.value.getRegistrationData()
                self?.handle(event: Event.complete(action, .requestWithdrawInfo(receiver: [regData?.firstName, regData?.lastName].compactMap({ $0 }).joined(separator: " "))))
                return
            }

            do {
                let result = try await service.repository.initiateSEPAPayment(
                    userId: userId,
                    accountId: action.accountId,
                    amount: action.amount,
                    iban: iban,
                    bic: bic
                )
                self?.handle(event: Event.complete(action, .initiated(
                    challengeId: result,
                    IBAN: iban,
                    BIC: bic
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
                    amount: action.amount,
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
                    amount: action.amount,
                    status: status
                )
                await self.database.set(for: userAction.id, userAction)
            }
        case let .sendFailure(action, _):
            Task { [weak self] in
                guard var userAction = await self?.database.get(for: action.id) else { return }
                userAction.status = .error(UserActionError.networkFailure)
                await self?.database.set(for: action.id, userAction)
            }
        }
    }
}

public struct OutgoingBankTransferUserAction: UserAction, Equatable {
    /// Unique internal id to track.
    public let id: String
    public let accountId: String
    public let amount: String // In cents
    /// Abstract status.
    public var status: UserActionStatus
    public var createdDate: Date
    public var updatedDate: Date
    public var result: OutgoingBankTransferUserActionResult?

    public init(
        id: String,
        accountId: String,
        amount: String,
        status: UserActionStatus,
        createdDate: Date = Date(),
        updatedDate: Date = Date()
    ) {
        self.id = id
        self.accountId = accountId
        self.amount = amount
        self.status = status
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }
}
