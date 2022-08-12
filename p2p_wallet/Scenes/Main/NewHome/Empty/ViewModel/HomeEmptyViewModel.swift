//
//  HomeEmptyViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

import Combine
import Foundation
import RenVMSwift
import Resolver
import RxCombine
import SolanaSwift

final class HomeEmptyViewModel: ObservableObject {
    let input = Input()
    let output: Output

    @Injected private var walletsRepository: WalletsRepository
    private let pricesService: PricesServiceType = Resolver.resolve()
    private var cancellable: AnyCancellable?

    let topUp = PassthroughSubject<Void, Never>()
    let topUpCoin = PassthroughSubject<Buy.CryptoCurrency, Never>()
    private let receiveRenBtc = PassthroughSubject<PublicKey, Never>()

    var popularCoins: [PopularCoin] {
        [
            PopularCoin(
                title: L10n.usdc,
                amount: pricesService.fiatAmount(for: Buy.CryptoCurrency.usdc.name),
                actionTitle: ActionType.buy.description,
                image: .usdc
            ),
            PopularCoin(
                title: L10n.solana,
                amount: pricesService.fiatAmount(for: Buy.CryptoCurrency.sol.name),
                actionTitle: ActionType.buy.description,
                image: .squircleSolanaIcon
            ),
            PopularCoin(
                title: "RenBTC",
                amount: pricesService.fiatAmount(for: "renBTC"),
                actionTitle: ActionType.receive.description,
                image: .renBTC
            ),
        ]
    }

    init() {
        output = Output(
            view: .init(),
            coord: .init(
                topUpShow: topUp.eraseToAnyPublisher(),
                topUpCoinShow: topUpCoin.eraseToAnyPublisher(),
                receiveRenBtcShow: receiveRenBtc.eraseToAnyPublisher()
            )
        )
    }

    func reloadData() async {
        walletsRepository.reload()

        return await withCheckedContinuation { continuation in
            cancellable = walletsRepository.stateObservable
                .asPublisher()
                .assertNoFailure()
                .sink(receiveValue: { [weak self] in
                    if $0 == .loaded || $0 == .error {
                        continuation.resume()
                        self?.cancellable = nil
                    }
                })
        }
    }

    func receiveRenBtcClicked() {
        guard let solanaPubkey = try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) else { return }
        receiveRenBtc.send(solanaPubkey)
    }
}

// MARK: - ViewModel

extension HomeEmptyViewModel: ViewModel {
    struct Input: ViewModelIO {
        let view = View()
        let coord = Coord()

        struct View {}

        class Coord {}
    }

    struct Output: ViewModelIO {
        let view: View
        let coord: Coord

        class Coord {
            var topUpShow: AnyPublisher<Void, Never>
            var topUpCoinShow: AnyPublisher<Buy.CryptoCurrency, Never>
            var receiveRenBtcShow: AnyPublisher<PublicKey, Never>

            init(
                topUpShow: AnyPublisher<Void, Never>,
                topUpCoinShow: AnyPublisher<Buy.CryptoCurrency, Never>,
                receiveRenBtcShow: AnyPublisher<PublicKey, Never>
            ) {
                self.topUpShow = topUpShow
                self.topUpCoinShow = topUpCoinShow
                self.receiveRenBtcShow = receiveRenBtcShow
            }
        }

        struct View {}
    }
}

// MARK: - Model

extension HomeEmptyViewModel {
    class PopularCoin {
        let title: String
        let amount: String
        @Published var actionTitle: String
        let image: UIImage

        init(
            title: String,
            amount: String,
            actionTitle: String,
            image: UIImage
        ) {
            self.title = title
            self.amount = amount
            self.actionTitle = actionTitle
            self.image = image
        }
    }

    enum ActionType {
        case buy
        case receive

        fileprivate var description: String {
            switch self {
            case .buy:
                return L10n.buyIt
            case .receive:
                return L10n.receive
            }
        }
    }
}

private extension PricesServiceType {
    func fiatAmount(for token: String) -> String {
        "\(Defaults.fiat.symbol) \((currentPrice(for: token)?.value ?? 0).toString(minimumFractionDigits: 2, maximumFractionDigits: 2))"
    }
}
