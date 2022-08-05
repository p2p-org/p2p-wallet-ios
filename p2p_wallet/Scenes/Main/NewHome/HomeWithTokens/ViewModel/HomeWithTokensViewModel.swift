//
//  HomeWithTokensViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import Combine
import Foundation
import Resolver
import RxCombine
import RxSwift
import SolanaSwift
import UIKit

class HomeWithTokensViewModel: ObservableObject {
    typealias Model = TokenCellView.Model

    private let walletsRepository: WalletsRepository
    private let pricesService = Resolver.resolve(PricesServiceType.self)

    private let buyClicked = PassthroughSubject<Void, Never>()
    private let receiveClicked = PassthroughSubject<Void, Never>()
    private let sendClicked = PassthroughSubject<Void, Never>()
    private let tradeClicked = PassthroughSubject<Void, Never>()
    let buyShow: AnyPublisher<Void, Never>
    let receiveShow: AnyPublisher<PublicKey, Never>
    let sendShow: AnyPublisher<Void, Never>
    let tradeShow: AnyPublisher<Void, Never>

    @Published var balance = ""
    @Published var pullToRefreshPending = false
    @Published var scrollOnTheTop = true
    @Published var items = [Model]()

    private var cancellables = Set<AnyCancellable>()

    init(walletsRepository: WalletsRepository = Resolver.resolve()) {
        self.walletsRepository = walletsRepository

        buyShow = buyClicked.eraseToAnyPublisher()
        receiveShow = receiveClicked
            .compactMap { try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) }
            .eraseToAnyPublisher()
        sendShow = sendClicked.eraseToAnyPublisher()
        tradeShow = tradeClicked.eraseToAnyPublisher()

        Observable.zip(walletsRepository.dataObservable, walletsRepository.stateObservable)
            .map { data, state in
                let data = data ?? []
                switch state {
                case .initializing:
                    return ""
                case .loading:
                    return L10n.loading + "..."
                case .loaded:
                    let equityValue = data.reduce(0) { $0 + $1.amountInCurrentFiat }
                    return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
                case .error:
                    return L10n.error.uppercaseFirst
                }
            }
            .asPublisher()
            .assertNoFailure()
            .sink(receiveValue: { [weak self] in
                self?.balance = $0
            })
            .store(in: &cancellables)
        walletsRepository.stateObservable
            .asPublisher()
            .assertNoFailure()
            .sink(receiveValue: { [weak self] in
                switch $0 {
                case .initializing, .loading:
                    break
                case .loaded:
                    self?.pullToRefreshPending = false
                case .error:
                    break // Сделать отображение ошибки
                }
            })
            .store(in: &cancellables)
        walletsRepository.dataObservable
            .asPublisher()
            .assertNoFailure()
            .sink(receiveValue: { [weak self] wallets in
                guard let self = self, let wallets = wallets else { return }
                self.items = wallets.map {
                    .init(
                        imageUrl: $0.token.logoURI ?? "",
                        title: $0.name,
                        subtitle: $0.amount?.tokenAmount(symbol: $0.token.symbol) ?? "",
                        amount: $0.amountInCurrentFiat.fiatAmount(),
                        wrappedImage: $0.token.wrappedBy?.image
                    )
                }
            })
            .store(in: &cancellables)
    }

//    if let token = token {
//        if let image = token.image {
//            tokenIcon.image = image
//        } else {
//            let key = token.symbol.isEmpty ? token.address : token.symbol
//            var seed = Self.cachedJazziconSeeds[key]
//            if seed == nil {
//                seed = UInt32.random(in: 0 ..< 10_000_000)
//                Self.cachedJazziconSeeds[key] = seed
//            }
//
//            tokenIcon.isHidden = true
//            self.seed = seed
//
//            tokenIcon.setImage(urlString: token.logoURI) { [weak self] result in
//                switch result {
//                case .success:
//                    self?.tokenIcon.isHidden = false
//                    self?.seed = nil
//                case .failure:
//                    self?.tokenIcon.isHidden = true
//                }
//            }
//        }
//    } else {
//        tokenIcon.image = placeholder
//    }

    func reloadData() {
        walletsRepository.reload()
    }

    func buy() {
        buyClicked.send()
    }

    func receive() {
        receiveClicked.send()
    }

    func send() {
        sendClicked.send()
    }

    func trade() {
        tradeClicked.send()
    }

    func scrollToTop() {
        scrollOnTheTop = true
    }
}
