import Combine
import Foundation
import Combine
import Resolver
import RxSwift
import KeyAppUI
import SolanaSwift

@MainActor
class SellViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies
    // TODO: Put resolver
    private let dataService: any SellDataService = SellDataServiceMock()
    private let actionService: SellActionService = SellActionServiceMock()
    @Injected private var walletRepository: WalletsRepository

    let coordinator = CoordinatorIO()
    private let disposeBag = DisposeBag()

    // MARK: -

    @Published var isLoading = true
    @Published var sellAllText = NSAttributedString(string: "Sell All")
    @Published var cryptoAmount: String = ""

    override init() {
        super.init()

        warmUp()

        let dataStatus = dataService.status
            .receive(on: RunLoop.main)
            .share()

        // 1. Check if pending txs
        dataStatus
            .filter { $0 == .ready }
            .map { _ in false }
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)

        dataStatus
            .filter { $0 == .ready }
            .sink { _ in self.coordinator.showPending.send() }
            .store(in: &subscriptions)

        walletRepository.dataDidChange
            .subscribe(onNext: { val in
                 let str = NSMutableAttributedString(
                    string: "Sell All ",
                    attributes: [
                        .font: UIFont.fontSize(of: .label1),
                        .foregroundColor: Asset.Colors.mountain.color
                    ]
                )
                str.appending(NSAttributedString(
                    string: (self.walletRepository.nativeWallet?.amount.toString() ?? "") + " "
                    + self.walletRepository.nativeWallet?.token.symbol,
                    attributes: [
                        .font: UIFont.fontSize(of: .label1),
                        .foregroundColor: Asset.Colors.sky.color
                    ]
                ))
                self.sellAllText = str
            })
            .disposed(by: disposeBag)
    }

    private func warmUp() {
        Task {
            try await dataService.update()
        }
    }

    // MARK: - Actions

    func sell() {
        try! openProviderWebView(
            quoteCurrencyCode: dataService.fiat.code,
            baseCurrencyAmount: 10, // 10 SOL
            externalTransactionId: UUID().uuidString
        )
    }

    func sellAll() {
        cryptoAmount = self.walletRepository.nativeWallet?.amount.toString() ?? ""
    }

    func openProviderWebView(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalTransactionId: String
    ) throws {
        let url = try actionService.createSellURL(
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount,
            externalTransactionId: externalTransactionId
        )
        navigation.send(.webPage(url: url))
    }
}
