//
//  HomeEmptyViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import RenVMSwift
import Resolver
import SolanaSwift

final class HomeEmptyViewModel: ObservableObject {
    let input = Input()
    let output: Output

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var walletsRepository: WalletsRepository
    private let pricesService: PricesServiceType = Resolver.resolve()
    private var cancellable: AnyCancellable?
    
    let topUp = PassthroughSubject<Void, Never>()
    let topUpCoin = PassthroughSubject<Token, Never>()
    let receiveSubject = PassthroughSubject<PublicKey, Never>()
    
    private var _popularCoins: [Token] = [.usdc, .nativeSolana, .renBTC, .eth, .usdt]
    var popularCoins: [PopularCoin] {
        _popularCoins.map { token in
            PopularCoin(
                id: token.symbol,
                title: title(for: token),
                amount: pricesService.fiatAmount(for: token.symbol),
                actionTitle: ActionType.buy.description,
                image: image(for: token)
            )
        }
    }
    
    init() {
        output = Output(
            view: .init(),
            coord: .init(
                topUpShow: topUp.eraseToAnyPublisher(),
                topUpCoinShow: topUpCoin.eraseToAnyPublisher(),
                receive: receiveSubject.eraseToAnyPublisher()
            )
        )
    }
    
    func reloadData() async {
        walletsRepository.reload()
        
        return await withCheckedContinuation { continuation in
            cancellable = walletsRepository
                .statePublisher
                .assertNoFailure()
                .sink(receiveValue: { [weak self] in
                    if $0 == .loaded || $0 == .error {
                        continuation.resume()
                        self?.cancellable = nil
                    }
                })
        }
    }

    func receiveClicked() {
        guard let solanaPubkey = try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) else { return }
        receiveSubject.send(solanaPubkey)
    }
    
    func buyTapped(index: Int) {
        let coin = _popularCoins[index]
        analyticsManager.log(event: AmplitudeEvent.mainScreenBuyToken(tokenName: coin.symbol))
        topUpCoin.send(coin)
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
            var topUpCoinShow: AnyPublisher<Token, Never>
            var receive: AnyPublisher<PublicKey, Never>

            init(
                topUpShow: AnyPublisher<Void, Never>,
                topUpCoinShow: AnyPublisher<Token, Never>,
                receive: AnyPublisher<PublicKey, Never>
            ) {
                self.topUpShow = topUpShow
                self.topUpCoinShow = topUpCoinShow
                self.receive = receive
            }
        }

        struct View {}
    }
}

// MARK: - Model

extension HomeEmptyViewModel {
    class PopularCoin {
        let id: String
        let title: String
        let amount: String
        @Published var actionTitle: String
        let image: UIImage

        init(
            id: String,
            title: String,
            amount: String,
            actionTitle: String,
            image: UIImage
        ) {
            self.id = id
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
                return L10n.buy
            case .receive:
                return L10n.receive
            }
        }
    }
}

extension HomeEmptyViewModel {
    func title(for token: Token) -> String {
        if token == .eth {
            return "Ethereum"
        } else if token == .renBTC {
            return L10n.bitcoin
        }
        return token.name
    }

    func image(for token: Token) -> UIImage {
        if token == .nativeSolana {
            return .solanaIcon
        }
        if token == .usdc {
            return .usdcIcon
        }
        if token == .usdt {
            return .usdtIcon
        }
        if token == .eth {
            return .ethereumIcon
        }
        if token == .renBTC {
            return .bitcoinIcon
        }
        return token.image ?? .squircleSolanaIcon
    }
}

private extension PricesServiceType {
    func fiatAmount(for token: String) -> String {
        "\(Defaults.fiat.symbol) \((currentPrice(for: token)?.value ?? 0).toString(minimumFractionDigits: 2, maximumFractionDigits: 2))"
    }
}
