//
//  DepositSolendViewModekl.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.09.2022.
//

import Combine
import FeeRelayerSwift
import Foundation
import Resolver
import SolanaSwift
import Solend

@MainActor
class DepositSolendViewModel: ObservableObject {
    private let dataService: SolendDataService
    private let actionService: SolendActionService
    @Injected private var notificationService: NotificationService
    // private let

    var subscriptions = Set<AnyCancellable>()

    @Published var loading: Bool = false
    @Published var input: String = "" {
        didSet {
            inputLamport = inputInLamport
            Task {
                let fee = try await self.actionService.depositFee(amount: inputInLamport, symbol: invest.asset.symbol)
                self.depositFee = fee
            }
        }
    }

    @Published var invest: Invest
    @Published var depositFee: SolendDepositFee? = nil
    @Published var inputLamport: UInt64 = 0

    init(initialAsset: SolendConfigAsset, mocked: Bool = false) throws {
        dataService = mocked ? SolendDataServiceMock() : Resolver.resolve(SolendDataService.self)
        actionService = mocked ? SolendActionServiceMock() : Resolver.resolve(SolendActionService.self)
        invest = (asset: initialAsset, market: nil, userDeposit: nil)

        dataService.marketInfo
            .sink { [weak self] markets in
                guard let self = self else { return }
                let marketInfo = markets?.first { $0.symbol == self.invest.asset.symbol }
                self.invest.market = marketInfo
            }
            .store(in: &subscriptions)

        dataService.deposits
            .sink { [weak self] deposits in
                guard let self = self else { return }
                let deposit = deposits?.first { $0.symbol == self.invest.asset.symbol }
                self.invest.userDeposit = deposit
            }
            .store(in: &subscriptions)
    }

    var inputInLamport: UInt64 {
        guard let amount = Double(input) else { return 0 }
        return UInt64(amount * pow(10, Double(invest.asset.decimals)))
    }

    func deposit() async throws {
        guard loading == false, inputInLamport > 0 else { return }
        do {
            loading = true
            defer { loading = false }

            try await actionService.deposit(amount: inputInLamport, symbol: invest.asset.symbol)
        } catch {
            notificationService.showInAppNotification(.error(error.localizedDescription))
        }
    }
}
