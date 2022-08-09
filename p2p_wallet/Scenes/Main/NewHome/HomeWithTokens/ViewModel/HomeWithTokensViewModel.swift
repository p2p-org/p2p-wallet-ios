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
    private let walletClicked = PassthroughSubject<(pubKey: String, tokenSymbol: String), Never>()
    let buyShow: AnyPublisher<Void, Never>
    let receiveShow: AnyPublisher<PublicKey, Never>
    let sendShow: AnyPublisher<Void, Never>
    let tradeShow: AnyPublisher<Void, Never>
    let walletShow: AnyPublisher<(pubKey: String, tokenSymbol: String), Never>

    @Published var balance = ""
    @Published var pullToRefreshPending = false
    @Published var scrollOnTheTop = true

    private var wallets = [Wallet]()
    @Published var items = [Model]()
    @Published var hiddenItems = [Model]()

    @Published var tokensIsHidden: Bool

    private var cancellables = Set<AnyCancellable>()

    init(walletsRepository: WalletsRepository = Resolver.resolve()) {
        self.walletsRepository = walletsRepository

        tokensIsHidden = !walletsRepository.isHiddenWalletsShown.value

        buyShow = buyClicked.eraseToAnyPublisher()
        receiveShow = receiveClicked
            .compactMap { try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) }
            .eraseToAnyPublisher()
        sendShow = sendClicked.eraseToAnyPublisher()
        tradeShow = tradeClicked.eraseToAnyPublisher()
        walletShow = walletClicked.eraseToAnyPublisher()

        Observable.zip(walletsRepository.dataObservable, walletsRepository.stateObservable)
            .filter { $0.1 == .loaded }
            .map { data, _ in
                let data = data ?? []
                let equityValue = data.reduce(0) { $0 + $1.amountInCurrentFiat }
                return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
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
                case .loaded, .error:
                    self?.pullToRefreshPending = false
                }
            })
            .store(in: &cancellables)
        walletsRepository.dataObservable
            .asPublisher()
            .assertNoFailure()
            .sink(receiveValue: { [weak self] wallets in
                guard let self = self, let wallets = wallets else { return }
                self.wallets = wallets
                let items = wallets.map {
                    (
                        Model(
                            imageUrl: $0.token.logoURI ?? "",
                            title: $0.name,
                            subtitle: $0.amount?.tokenAmount(symbol: $0.token.symbol) ?? "",
                            amount: $0.amountInCurrentFiat.fiatAmount(),
                            wrappedImage: $0.token.wrappedBy?.image
                        ),
                        $0.isHidden
                    )
                }
                self.items = items.filter { !$0.1 }.map(\.0)
                self.hiddenItems = items.filter(\.1).map(\.0)
            })
            .store(in: &cancellables)
    }

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

    func tokenClicked(model: Model) {
        guard
            let wallet = (wallets.first { $0.name == model.title }),
            let pubKey = wallet.pubkey
        else { return }
        walletClicked.send((pubKey: pubKey, tokenSymbol: wallet.token.symbol))
    }

    func scrollToTop() {
        scrollOnTheTop = true
    }

    func toggleTokenVisibility(model: Model) {
        guard let wallet = (wallets.first { $0.name == model.title }) else { return }
        walletsRepository.toggleWalletVisibility(wallet)
    }

    func toggleHiddenTokensVisibility() {
        walletsRepository.toggleIsHiddenWalletShown()
        tokensIsHidden.toggle()
    }
}
