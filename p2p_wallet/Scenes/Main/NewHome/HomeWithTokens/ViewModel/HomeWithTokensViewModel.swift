//
//  HomeWithTokensViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import Combine
import Foundation
import Resolver
import SolanaSwift
import UIKit

class HomeWithTokensViewModel: ObservableObject {
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
    @Published var scrollOnTheTop = true

    private var wallets = [Wallet]()
    @Published var items = [Wallet]()
    @Published var hiddenItems = [Wallet]()

    @Published var tokensIsHidden: Bool

    private var cancellables = Set<AnyCancellable>()
    private var reloadCancellable: AnyCancellable?

    init(walletsRepository: WalletsRepository = Resolver.resolve()) {
        self.walletsRepository = walletsRepository

        tokensIsHidden = !walletsRepository.isHiddenWalletsShown

        buyShow = buyClicked.eraseToAnyPublisher()
        receiveShow = receiveClicked
            .compactMap { try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) }
            .eraseToAnyPublisher()
        sendShow = sendClicked.eraseToAnyPublisher()
        tradeShow = tradeClicked.eraseToAnyPublisher()
        walletShow = walletClicked.eraseToAnyPublisher()

        walletsRepository.statePublisher
            .filter { $0 == .loaded }
            .withLatestFrom(walletsRepository.dataPublisher)
            .map { data in
                let data = data
                let equityValue = data.reduce(0) { $0 + $1.amountInCurrentFiat }
                return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
            }
            .assertNoFailure()
            .sink(receiveValue: { [weak self] in
                self?.balance = $0
            })
            .store(in: &cancellables)

        walletsRepository.dataPublisher
            .assertNoFailure()
            .sink(receiveValue: { [weak self] wallets in
                guard let self = self else { return }
                var wallets = wallets
                // Hide NFT TODO: $0.token.supply == 1 is also a condition for NFT but skipped atm
                wallets = wallets.filter { !($0.token.decimals == 0) }
                self.wallets = wallets
                let items = wallets.map {
                    (
                        $0,
                        $0.isHidden
                    )
                }
                self.items = items.filter { !$0.1 }.map(\.0)
                self.hiddenItems = items.filter(\.1).map(\.0)
            })
            .store(in: &cancellables)
    }

    func reloadData() async {
        walletsRepository.reload()
        return await withCheckedContinuation { continuation in
            reloadCancellable = walletsRepository.statePublisher
                .assertNoFailure()
                .sink(receiveValue: { [weak self] in
                    if $0 == .loaded || $0 == .error {
                        continuation.resume()
                        self?.reloadCancellable = nil
                    }
                })
        }
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

    func tokenClicked(wallet: Wallet) {
        guard let pubKey = wallet.pubkey else { return }
        walletClicked.send((pubKey: pubKey, tokenSymbol: wallet.token.symbol))
    }

    func scrollToTop() {
        scrollOnTheTop = true
    }

    func toggleTokenVisibility(wallet: Wallet) {
        walletsRepository.toggleWalletVisibility(wallet)
    }

    func toggleHiddenTokensVisibility() {
        walletsRepository.toggleIsHiddenWalletShown()
        tokensIsHidden.toggle()
    }
}
