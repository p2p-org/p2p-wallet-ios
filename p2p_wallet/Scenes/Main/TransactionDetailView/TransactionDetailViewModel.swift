import AnalyticsManager
import Combine
import Foundation
import History
import KeyAppBusiness
import Resolver
import SolanaSwift
import TransactionParser

enum TransactionDetailStyle {
    case active
    case passive
}

enum TransactionDetailViewModelOutput {
    case share(URL)
    case open(URL)
    case close
}

class TransactionDetailViewModel: BaseViewModel, ObservableObject {
    @Injected private var transactionHandler: TransactionHandler
    @Injected private var analyticsManager: AnalyticsManager

    @Published var rendableTransaction: any RenderableTransactionDetail

    @Published var forceHidingStatus: Bool = false

    let style: TransactionDetailStyle

    let action = PassthroughSubject<TransactionDetailViewModelOutput, Never>()

    var statusContext: String?

    init(rendableDetailTransaction: any RenderableTransactionDetail, style: TransactionDetailStyle = .active) {
        self.style = style
        rendableTransaction = rendableDetailTransaction
    }

    init(parsedTransaction: ParsedTransaction) {
        style = .passive
        rendableTransaction = RendableDetailParsedTransaction(trx: parsedTransaction)
    }

    init(historyTransaction: HistoryTransaction) {
        style = .passive
        rendableTransaction = RendableDetailHistoryTransaction(trx: historyTransaction, allTokens: [])

        super.init()

        Task {
            let tokenRepository: TokensRepository = Resolver.resolve()
            self.rendableTransaction = try await RendableDetailHistoryTransaction(
                trx: historyTransaction,
                allTokens: tokenRepository.getTokensList(useCache: true)
            )
        }
    }

    init(pendingTransaction: PendingTransaction, statusContext: String? = nil) {
        let pendingService: TransactionHandlerType = Resolver.resolve()
        let priceService: PricesService = Resolver.resolve()

        style = .active
        self.statusContext = statusContext
        rendableTransaction = RendableDetailPendingTransaction(trx: pendingTransaction, priceService: priceService)

        super.init()

        pendingService
            .observeTransaction(transactionIndex: pendingTransaction.trxIndex)
            .sink { trx in
                guard let trx = trx else { return }
                self.rendableTransaction = RendableDetailPendingTransaction(trx: trx, priceService: priceService)
            }
            .store(in: &subscriptions)
    }

    init(userAction: any UserAction) {
        let userActionService: UserActionService = Resolver.resolve()

        style = .active
        rendableTransaction = RendableGeneralUserActionTransaction.resolve(userAction: userAction)

        super.init()

        // Hide status in case transaction is ready
        switch rendableTransaction.status {
        case .succeed:
            forceHidingStatus = true
        default:
            forceHidingStatus = false
        }

        if userAction.status != .ready {
            userActionService
                .observer(id: userAction.id)
                .receive(on: RunLoop.main)
                .sink { userAction in
                    self.rendableTransaction = RendableGeneralUserActionTransaction.resolve(userAction: userAction)
                }
                .store(in: &subscriptions)
        }
    }

    func share() {
        guard let url = URL(string: rendableTransaction.url ?? "")
        else { return }
        action.send(.share(url))
    }

    func explore() {
        analyticsManager.log(event: .transactionBlockchainLinkClick)
        guard let url = URL(string: rendableTransaction.url ?? "")
        else { return }
        action.send(.open(url))
    }
}
