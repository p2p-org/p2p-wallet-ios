//
//  SolendTopUpForContinueView.swift
//  p2p_wallet
//
//  Created by Ivan on 27.09.2022.
//

import Combine
import Foundation
import Resolver
import SolanaSwift
import Solend

class SolendTopUpForContinueViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()

    private let closeSubject = PassthroughSubject<Void, Never>()
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }

    private let buySubject = PassthroughSubject<Void, Never>()
    var buy: AnyPublisher<Void, Never> { buySubject.eraseToAnyPublisher() }

    private let receiveSubject = PassthroughSubject<PublicKey, Never>()
    var receive: AnyPublisher<PublicKey, Never> { receiveSubject.eraseToAnyPublisher() }

    private let swapSubject = PassthroughSubject<Void, Never>()
    var swap: AnyPublisher<Void, Never> { swapSubject.eraseToAnyPublisher() }

    @Injected private var walletsRepository: WalletsRepository
    private var dataService: SolendDataService

    let model: SolendTopUpForContinueModel
    let usdcOrSol: Bool
    let symbol: String
    let name: String
    @Published var apy: String = ""
    let imageUrl: URL?
    let firstActionTitle: String
    let withoutAnyTokens: Bool

    init(model: SolendTopUpForContinueModel, dataService: SolendDataService = Resolver.resolve()) {
        self.model = model
        self.dataService = dataService

        usdcOrSol = model.asset.symbol == "SOL" || model.asset.symbol == "USDC"
        symbol = model.asset.symbol
        name = model.asset.name
        imageUrl = URL(string: model.asset.logo ?? "")
        firstActionTitle = model.strategy == .withoutAnyTokens ? "Trade for \(symbol)" : "\(L10n.buy) \(symbol)"
        withoutAnyTokens = model.strategy == .withoutAnyTokens

        dataService.marketInfo.sink { [weak self] (marketInfos: [SolendMarketInfo]?) in
            guard let self = self else { return }
            let marketInfo: SolendMarketInfo? = marketInfos?.first { $0.symbol == self.symbol }
            guard let marketInfo = marketInfo, let apy = Double(marketInfo.supplyInterest) else {
                self.apy = ""
                return
            }
            self.apy = apy.percentFormat()
        }.store(in: &subscriptions)
    }

    func closeClicked() {
        closeSubject.send()
    }

    func buyClicked() {
        buySubject.send()
    }

    func swapOrReceiveClicked() {
        if withoutAnyTokens {
            guard let key = try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) else { return }
            receiveSubject.send(key)
        } else {
            swapSubject.send()
        }
    }
}
