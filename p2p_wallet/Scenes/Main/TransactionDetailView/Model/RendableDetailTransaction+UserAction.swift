import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Send
import Wormhole

struct RendableGeneralUserActionTransaction {
    static func resolve(userAction: any UserAction) -> RenderableTransactionDetail {
        switch userAction {
        case let userAction as WormholeSendUserAction:
            return RendableWormholeSendUserActionDetail(userAction: userAction)
        case let userAction as WormholeClaimUserAction:
            return RenderableWormholeClaimUserActionDetail(userAction: userAction)
        default:
            return RendableAbstractUserActionTransaction(userAction: userAction)
        }
    }
}

struct RendableAbstractUserActionTransaction: RenderableTransactionDetail {
    let userAction: any UserAction

    var status: TransactionDetailStatus {
        switch userAction.status {
        case .pending, .processing:
            return .loading(message: L10n.itUsuallyTakesFewSecondsForATransactionToComplete)
        case .ready:
            return .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted)
        case let .error(error):
            return .error(
                message: NSAttributedString(string: L10n.OopsSomethingWentWrong.pleaseTryAgainLater),
                error: error
            )
        }
    }

    var title: String {
        switch userAction.status {
        case .pending, .processing:
            return L10n.transactionSubmitted
        case .ready:
            return L10n.transactionSucceeded
        case let .error(error):
            return L10n.transactionFailed
        }
    }

    var subtitle: String {
        ""
    }

    var signature: String? {
        ""
    }

    var icon: TransactionDetailIcon {
        .icon(.planet)
    }

    var amountInFiat: TransactionDetailChange {
        .unchanged("")
    }

    var amountInToken: String {
        ""
    }

    var extra: [TransactionDetailExtraInfo] {
        []
    }

    var actions: [TransactionDetailAction] {
        []
    }

    var buttonTitle: String {
        L10n.done
    }
    
    var url: String? {
        nil
    }
}
