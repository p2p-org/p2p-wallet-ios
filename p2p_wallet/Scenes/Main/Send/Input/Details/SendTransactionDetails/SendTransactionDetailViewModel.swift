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
import SolanaSwift
import SwiftUI

final class SendTransactionDetailViewModel: BaseViewModel, ObservableObject {
    let cancelSubject = PassthroughSubject<Void, Never>()
    let feePrompt = PassthroughSubject<[Wallet], Never>()

    private let stateMachine: SendInputStateMachine
    @Injected private var pricesService: PricesServiceType
    @Injected private var walletsRepository: WalletsRepository

    private lazy var feeWalletsService: SendChooseFeeService = SendChooseFeeServiceImpl(
        wallets: walletsRepository.getWallets(),
        feeRelayer: Resolver.resolve(),
        orcaSwap: Resolver.resolve()
    )

    @Published var cellModels: [CellModel] = []
    @Published var accountCreationFeeCellModel: CellModel?

    init(stateMachine: SendInputStateMachine) {
        self.stateMachine = stateMachine
        super.init()

        stateMachine.statePublisher
            .sink { [weak self] (state: SendInputState) in
                guard let self = self else { return }
                self.accountCreationFeeCellModel = self.extractAccountCreationFeeCellModel(state: state, isLoading: true, feeTokens: nil)
                self.updateCells(for: state)
                Task {
                    let tokens = try? await self.feeWalletsService.getAvailableWalletsToPayFee(feeInSOL: stateMachine.currentState.fee)
                    self.accountCreationFeeCellModel = self.extractAccountCreationFeeCellModel(state: state, isLoading: false, feeTokens: tokens)
                    self.updateCells(for: state)
                }
            }
            .store(in: &subscriptions)
    }

    private func extractTransactionFeeCellModel(state: SendInputState) -> CellModel {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return .init(
                title: L10n.transactionFee,
                subtitle: [("", nil)],
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
            subtitle: [(
                state.fee.transaction == 0 ? L10n
                    .freeLeftForToday(remainUsage) : amountFeeInToken.tokenAmount(symbol: state.tokenFee.symbol),
                state.fee.transaction == 0 ? nil : "\(Defaults.fiat.symbol)\(amountFeeInFiat.fixedDecimal(2))"
            )],
            image: .transactionFee,
            isFree: state.fee.transaction == 0
        )
    }

    private func extractAccountCreationFeeCellModel(state: SendInputState, isLoading: Bool, feeTokens: [Wallet]?) -> CellModel? {
        guard state.fee.accountBalances > 0
        else {
            return nil
        }

        let amountFeeInToken = Double(state.feeInToken.accountBalances) / pow(10, Double(state.tokenFee.decimals))
        let amountFeeInFiat: Double = amountFeeInToken *
            (pricesService.currentPrice(for: state.tokenFee.symbol)?.value ?? 0)

        return CellModel(
            title: L10n.accountCreationFee,
            subtitle: [(
                amountFeeInToken.tokenAmount(symbol: state.tokenFee.symbol, maximumFractionDigits: Int(state.tokenFee.decimals)),
                "\(Defaults.fiat.symbol)\(amountFeeInFiat.fixedDecimal(2))"
            )],
            image: .accountCreationFee,
            info: feeTokens == nil ? nil : { [weak self] in self?.feePrompt.send(feeTokens ?? []) },
            isLoading: isLoading
        )
    }

    private func extractTotalCellModel(state: SendInputState) -> CellModel {
        var subtitles: [(String, String?)] = []

        var totalAmount: Lamports = state.amountInToken.toLamport(decimals: state.token.decimals)
        if state.token.address == state.tokenFee.address {
            totalAmount += state.feeInToken.total
        } else {
            if state.feeInToken.transaction > 0 {
                subtitles.append(convert(state.feeInToken.transaction, state.tokenFee))
            }

            if state.feeInToken.accountBalances > 0 {
                subtitles.append(convert(state.feeInToken.accountBalances, state.tokenFee))
            }
        }

        subtitles.insert(convert(totalAmount, state.token), at: 0)

        return CellModel(
            title: L10n.total,
            subtitle: subtitles,
            image: .totalSend
        )
    }

    private func convert(_ input: Lamports, _ token: Token) -> (String, String?) {
        let amountInToken: Double = input.convertToBalance(decimals: token.decimals)
        let amountInFiat: Double = amountInToken * (pricesService.currentPrice(for: token.symbol)?.value ?? 0)

        return (amountInToken.tokenAmount(symbol: token.symbol, maximumFractionDigits: Int(token.decimals)), "\(Defaults.fiat.symbol)\(amountInFiat.fixedDecimal(2))")
    }

    private func updateCells(for state: SendInputState) {
        cellModels = [
            CellModel(
                title: L10n.recipientSAddress,
                subtitle: [(state.recipient.address, nil)],
                image: .recipientAddress
            ),
            CellModel(
                title: L10n.recipientGets,
                subtitle: [convert(state.amountInToken.toLamport(decimals: state.token.decimals), state.token)],
                image: .recipientGet
            ),
            extractTransactionFeeCellModel(state: state),
            accountCreationFeeCellModel,
            extractTotalCellModel(state: state),
        ].compactMap { $0 }
    }
}

extension SendTransactionDetailViewModel {
    struct CellModel: Identifiable {
        let title: String
        let subtitle: [(String, String?)]
        let image: UIImage
        var isFree: Bool = false
        var info: (() -> Void)?
        var isLoading: Bool = false

        var id: String { title }
    }
}
