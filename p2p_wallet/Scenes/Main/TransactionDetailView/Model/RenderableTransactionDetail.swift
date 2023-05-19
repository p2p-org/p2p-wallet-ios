import Combine
import Foundation
import History
import SolanaSwift
import TransactionParser

protocol RenderableTransactionDetail {
    var status: TransactionDetailStatus { get }

    var title: String { get }

    var subtitle: String { get }

    var signature: String? { get }

    var icon: TransactionDetailIcon { get }

    var amountInFiat: TransactionDetailChange { get }

    var amountInToken: String { get }

    var extra: [TransactionDetailExtraInfo] { get }

    var actions: [TransactionDetailAction] { get }

    var buttonTitle: String { get }
    
    var url: String? { get }
}

struct TransactionDetailExtraInfo {
    struct Value: Identifiable {
        let text: String
        let secondaryText: String?

        static let defaultSecondaryTextFormatter = { (x: String) -> String in "(\(x))" }

        init(
            text: String,
            secondaryText: String? = nil,
            secondaryFormatter: (String) -> String = defaultSecondaryTextFormatter
        ) {
            self.text = text

            if let secondaryText {
                self.secondaryText = secondaryFormatter(secondaryText)
            } else {
                self.secondaryText = nil
            }
        }

        var id: String { text + secondaryText }
    }

    let title: String
    
    let values: [Value]

    let copyableValue: String?
    
    let url: String? = nil

    init(title: String, values: [Value], copyableValue: String? = nil) {
        self.title = title
        self.values = values
        self.copyableValue = copyableValue
    }
}

enum TransactionDetailAction: Int, Identifiable {
    var id: Int { rawValue }

    case share
    case explorer
}

enum TransactionDetailIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}

enum TransactionDetailChange {
    case positive(String)
    case negative(String)
    case unchanged(String)

    var value: String {
        switch self {
        case let .positive(value): return value
        case let .negative(value): return value
        case let .unchanged(value): return value
        }
    }
}

enum TransactionDetailStatus {
    case loading(message: String)
    case succeed(message: String)
    case error(message: NSAttributedString, error: Error?)
}

extension TransactionDetailStatus: Equatable {
    static func == (lhs: TransactionDetailStatus, rhs: TransactionDetailStatus) -> Bool {
        switch (lhs, rhs) {
        case let (.loading(lhsMessage), .loading(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.succeed(lhsMessage), .succeed(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.error(lhsMessage, lhsError), .error(rhsMessage, rhsError)):
            return lhsMessage == rhsMessage && lhsError?.localizedDescription == rhsError?.localizedDescription
        default:
            return false
        }
    }
}
