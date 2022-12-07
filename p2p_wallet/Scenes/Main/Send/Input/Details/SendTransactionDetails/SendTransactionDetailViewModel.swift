//
//  SendTransactionDetails.swift
//  p2p_wallet
//
//  Created by Ivan on 28.11.2022.
//

import Combine
import KeyAppUI
import Resolver
import Send
import SwiftUI

final class SendTransactionDetailViewModel: BaseViewModel, ObservableObject {
    let cancelSubject = PassthroughSubject<Void, Never>()
    let feePrompt = PassthroughSubject<Void, Never>()

    private let stateMachine: SendInputStateMachine
    @Injected private var pricesService: PricesServiceType

    @Published var cellModels: [CellModel] = []

    init(stateMachine: SendInputStateMachine) {
        self.stateMachine = stateMachine
        super.init()

        stateMachine.statePublisher
            .sink { [weak self] (state: SendInputState) in
                guard let self = self else { return }
                self.cellModels = [
                    CellModel(
                        title: L10n.recipientSAddress,
                        subtitle: (state.recipient.address, nil),
                        image: .recipientAddress
                    ),
                    CellModel(
                        title: L10n.recipientGets,
                        subtitle: (
                            state.amountInToken.tokenAmount(symbol: state.token.symbol),
                            "\(Defaults.fiat.symbol)\(state.amountInFiat.fixedDecimal(2))"
                        ),
                        image: .recipientGet
                    ),
                    self.extractTransactionFeeCellModel(state: state),
                    self.extractAccountCreationFeeCellModel(state: state),
                    self.extractTotalCellModel(state: state),
                ].compactMap { $0 }
            }
            .store(in: &subscriptions)
    }

    func extractTransactionFeeCellModel(state: SendInputState) -> CellModel {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return .init(
                title: L10n.transactionFee,
                subtitle: ("", nil),
                image: .transactionFee,
                isFree: false
            )
        }

        let remainUsage = feeRelayerContext.usageStatus.maxUsage - feeRelayerContext.usageStatus.currentUsage

        let amountFeeInToken = Double(state.feeInToken.transaction) / pow(10, Double(state.tokenFee.decimals))
        let amountFeeInFiat: Double = amountFeeInToken *
            (pricesService.currentPrice(for: state.tokenFee.symbol)?.value ?? 0)

        return CellModel(
            title: L10n.transactionFee,
            subtitle: (
                state.fee.transaction == 0 ? L10n
                    .freeLeftForToday(remainUsage) : amountFeeInToken.tokenAmount(symbol: state.tokenFee.symbol),
                state.fee.transaction == 0 ? nil : "\(Defaults.fiat.symbol)\(amountFeeInFiat.fixedDecimal(2))"
            ),
            image: .transactionFee,
            isFree: state.fee.transaction == 0
        )
    }

    func extractAccountCreationFeeCellModel(state: SendInputState) -> CellModel? {
        guard
            let feeRelayerContext = state.feeRelayerContext,
            state.fee.accountBalances > 0
        else {
            return nil
        }

        let amountFeeInToken = Double(state.feeInToken.accountBalances) / pow(10, Double(state.tokenFee.decimals))
        let amountFeeInFiat: Double = amountFeeInToken *
            (pricesService.currentPrice(for: state.tokenFee.symbol)?.value ?? 0)

        return CellModel(
            title: L10n.accountCreationFee,
            subtitle: (
                amountFeeInToken.tokenAmount(symbol: state.tokenFee.symbol),
                "\(Defaults.fiat.symbol)\(amountFeeInFiat.fixedDecimal(2))"
            ),
            image: .accountCreationFee,
            info: { [weak self] in self?.feePrompt.send() }
        )
    }

    func extractTotalCellModel(state: SendInputState) -> CellModel {
        var amountFeeInToken: Double = state.amountInToken
        if state.token.address == state.tokenFee.address {
            amountFeeInToken += Double(state.feeInToken.total) / pow(10, Double(state.tokenFee.decimals))
        }

        let amountFeeInFiat: Double = amountFeeInToken *
            (pricesService.currentPrice(for: state.token.symbol)?.value ?? 0)

        return CellModel(
            title: L10n.total,
            subtitle: (
                amountFeeInToken.tokenAmount(symbol: state.token.symbol),
                "\(Defaults.fiat.symbol)\(amountFeeInFiat.fixedDecimal(2))"
            ),
            image: .totalSend
        )
    }
}

extension SendTransactionDetailViewModel {
    struct CellModel: Identifiable {
        let title: String
        let subtitle: (String, String?)
        let image: UIImage
        var isFree: Bool = false
        var info: (() -> Void)?

        var id: String { title }
    }
}
