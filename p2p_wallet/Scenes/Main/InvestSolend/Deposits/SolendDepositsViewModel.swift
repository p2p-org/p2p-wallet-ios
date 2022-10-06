import Combine
import Foundation
import Resolver
import SolanaSwift
import Solend

@MainActor
class SolendDepositsViewModel: ObservableObject {
    private let dataService: SolendDataService
    private var subscriptions = Set<AnyCancellable>()

    // MARK: -

    @Injected private var priceService: PricesService
    @Injected private var walletRepository: WalletsRepository

    @Published var deposits: [SolendUserDepositItem] = []

    typealias Asset = SolendConfigAsset
    private var depositSubject = PassthroughSubject<SolendUserDepositItem, Never>()
    var deposit: AnyPublisher<Asset, Never> {
        depositSubject.map(\.id)
            .combineLatest(dataService.availableAssets) { symbol, assets in
                assets?.first { $0.symbol == symbol }
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private var withdrawSubject = PassthroughSubject<SolendUserDepositItem, Never>()
    var withdraw: AnyPublisher<Asset, Never> {
        withdrawSubject.map(\.id)
            .combineLatest(dataService.availableAssets) { symbol, assets in
                assets?.first { $0.symbol == symbol }
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    init(dataService: SolendDataService? = nil) {
        self.dataService = dataService ?? Resolver.resolve(SolendDataService.self)

        self.dataService.availableAssets
            .combineLatest(self.dataService.marketInfo, self.dataService.deposits)
            .map { (assets: [SolendConfigAsset]?, marketInfo: [SolendMarketInfo]?, userDeposits: [SolendUserDeposit]?) -> [SolendUserDepositItem] in
                guard let assets = assets else { return [] }
                return assets.compactMap { asset -> SolendUserDepositItem? in
                    let invest = (
                        asset: asset,
                        market: marketInfo?.first(where: { $0.symbol == asset.symbol }),
                        userDeposit: userDeposits?.first(where: { $0.symbol == asset.symbol })
                    )
                    guard let userDeposit = invest.userDeposit else { return nil }
                    return SolendUserDepositItem(
                        id: asset.symbol,
                        logo: asset.logo,
                        title: userDeposit.depositedAmount,
                        subtitle: L10n.yielding + " \(self.formatAPY(invest.market?.supplyInterest.double ?? 0)) APY",
                        rightTitle: (self.priceService.currentPrice(for: asset.symbol)?.value * userDeposit
                            .depositedAmount.double).fiatAmount(currency: Defaults.fiat)
                    )
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: \.deposits, on: self)
            .store(in: &subscriptions)
    }

    // MARK: -

    func depositTapped(item: SolendUserDepositItem) {
        depositSubject.send(item)
    }

    func withdrawTapped(item: SolendUserDepositItem) {
        withdrawSubject.send(item)
    }

    private func formatAPY(_ apy: Double) -> String {
        "\(apy.fixedDecimal(2))%"
    }
}
