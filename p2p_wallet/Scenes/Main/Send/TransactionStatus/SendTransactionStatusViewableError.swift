import FeeRelayerSwift
import Foundation
import KeyAppNetworking
import SolanaSwift

protocol SendTransactionStatusViewableError: Error {
    func detail(feeAmount: String?) -> SendTransactionStatusDetailsParameters?
}

extension FeeRelayerError: SendTransactionStatusViewableError {
    func detail(feeAmount: String?) -> SendTransactionStatusDetailsParameters? {
        if message == "Topping up is successfull, but the transaction failed" {
            return .init(
                title: L10n.somethingWentWrong,
                description: L10n.unknownError,
                fee: feeAmount
            )
        }
        return nil
    }
}

extension APIClientError: SendTransactionStatusViewableError {
    func detail(feeAmount _: String?) -> SendTransactionStatusDetailsParameters? {
        switch self {
        case .blockhashNotFound:
            return .init(
                title: L10n.blockhashNotFound,
                description: L10n.theBankHasNotSeenTheGivenOrTheTransactionIsTooOldAndTheHasBeenDiscarded(
                    "", // blockhash ?? "",
                    "" // blockhash ?? ""
                )
            )
        case let .responseError(response) where response.message?.contains("Instruction") == true:
            return .init(
                title: L10n.errorProcessingInstruction0CustomProgramError0x1,
                description: L10n.AnErrorOccuredWhileProcessingAnInstruction
                    .theFirstElementOfTheTupleIndicatesTheInstructionIndexInWhichTheErrorOccured
            )
        case let .responseError(response) where response.message?.contains("Already processed") == true:
            return .init(
                title: L10n.thisTransactionHasAlreadyBeenProcessed,
                description: L10n.TheBankHasSeenThisTransactionBefore
                    .thisCanOccurUnderNormalOperationWhenAUDPPacketIsDuplicatedAsAUserErrorFromAClientNotUpdatingItsOrAsADoubleSpendAttack(
                        "" // blockhash ?? ""
                    )
            )
        case let .responseError(response):
            return .init(
                title: L10n.somethingWentWrong,
                description: response.message ?? L10n.unknownError
            )
        default:
            return nil
        }
    }
}

extension JSONRPCError: SendTransactionStatusViewableError where DataType == EmptyData {
    func detail(feeAmount _: String?) -> SendTransactionStatusDetailsParameters? {
        .init(title: L10n.somethingWentWrong, description: message ?? "")
    }
}

extension DecodingError: SendTransactionStatusViewableError {
    func detail(feeAmount _: String?) -> SendTransactionStatusDetailsParameters? {
        .init(title: L10n.somethingWentWrong, description: .init(reflecting: self))
    }
}
