import Combine
import Foundation
import Resolver
import SolanaSwift
import Solend

@MainActor
class SolendDepositsViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Services

    @Injected private var priceService: PricesService
    @Injected private var walletRepository: WalletsRepository
    private let dataService: SolendDataService
    
    // MARK: - State
    
    @Published var deposits: [SolendUserDepositItem] = []

    // MARK: - Coordinator
    
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
    
    // MARK: - Init

    init(dataService: SolendDataService = Resolver.resolve()) {
        self.dataService = dataService

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

    // MARK: - Actions

    func depositTapped(item: SolendUserDepositItem) {
        depositSubject.send(item)
    }

    func withdrawTapped(item: SolendUserDepositItem) {
        withdrawSubject.send(item)
    }
    
    // MARK: - Helpers

    private func formatAPY(_ apy: Double) -> String {
        "\(apy.fixedDecimal(2))%"
    }
}
