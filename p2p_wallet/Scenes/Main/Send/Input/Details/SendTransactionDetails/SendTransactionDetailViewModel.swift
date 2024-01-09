import Combine
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send
import SolanaSwift
import SwiftUI

final class SendTransactionDetailViewModel: BaseViewModel, ObservableObject {
    let cancelSubject = PassthroughSubject<Void, Never>()
    let feePrompt = PassthroughSubject<[SolanaAccount], Never>()
    let longTapped = PassthroughSubject<CellModel, Never>()

    private let stateMachine: SendInputStateMachine
    @Injected private var walletsRepository: SolanaAccountsService
    @Injected private var notificationsService: NotificationService
    @Injected private var clipboardManager: ClipboardManagerType

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
            .receive(on: RunLoop.main)
            .sink { [weak self] (state: SendInputState) in
                guard let self = self else { return }
                self.accountCreationFeeCellModel = self.extractAccountCreationFeeCellModel(
                    state: state,
                    isLoading: true,
                    feeTokens: nil
                )
                self.updateCells(for: state)
                Task { [weak self] in
                    guard let self else { return }
                    let tokens = try? await self.feeWalletsService
                        .getAvailableWalletsToPayFee(feeInSOL: stateMachine.currentState.fee)

                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        self.accountCreationFeeCellModel = self.extractAccountCreationFeeCellModel(
                            state: state,
                            isLoading: false,
                            feeTokens: tokens
                        )
                        self.updateCells(for: state)
                    }
                }
            }
            .store(in: &subscriptions)

        longTapped
            .sink { [weak self] cellModel in
                guard let self = self else { return }
                switch cellModel.type {
                case .address:
                    self.copyToClipboard(address: self.stateMachine.currentState.recipient.address)
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    private func extractTransactionFeeCellModel(state: SendInputState) -> CellModel {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return .init(
                type: .transactionFee,
                title: L10n.transactionFee,
                subtitle: [("", nil)],
                image: .transactionFee,
                isFree: false
            )
        }

        let remainUsage = feeRelayerContext.usageStatus.maxUsage - feeRelayerContext.usageStatus.currentUsage

        let amountFeeInToken = Double(state.feeInToken.transaction) / pow(10, Double(state.tokenFee.decimals))

        let mainText: String
        let secondaryText: String?

        switch true {
        case state.fee.transaction == 0 && remainUsage == 0:
            mainText = "0 \(state.tokenFee.symbol)"
            secondaryText = "\(Defaults.fiat.symbol) 0"
        case state.fee.transaction == 0:
            mainText = L10n.freeLeftForToday(remainUsage)
            secondaryText = nil
        default:
            mainText = amountFeeInToken.tokenAmountFormattedString(symbol: state.tokenFee.symbol, roundingMode: .down)

            if let price = state.feeWallet?.price?.doubleValue {
                let amountFeeInFiat: Double = amountFeeInToken * price
                secondaryText = amountFeeInFiat.fiatAmountFormattedString(
                    roundingMode: .down,
                    customFormattForLessThan1E_2: true
                )
            } else {
                secondaryText = nil
            }
        }

        return CellModel(
            type: .transactionFee,
            title: L10n.transactionFee,
            subtitle: [(mainText, secondaryText)],
            image: .transactionFee,
            isFree: state.fee.transaction == 0 && remainUsage > 0
        )
    }

    private func extractAccountCreationFeeCellModel(
        state: SendInputState, isLoading: Bool,
        feeTokens: [SolanaAccount]?
    ) -> CellModel? {
        guard state.fee.accountBalances > 0
        else {
            return nil
        }

        let amountFeeInToken = Double(state.feeInToken.accountBalances) / pow(10, Double(state.tokenFee.decimals))

        let amountFeeInFiat: Double?
        if let price = state.feeWallet?.price?.doubleValue {
            amountFeeInFiat = amountFeeInToken * price
        } else {
            amountFeeInFiat = nil
        }

        return CellModel(
            type: .accountCreationFee,
            title: L10n.accountCreationFee,
            subtitle: [(
                amountFeeInToken.tokenAmountFormattedString(
                    symbol: state.tokenFee.symbol,
                    maximumFractionDigits: Int(state.tokenFee.decimals),
                    roundingMode: .down
                ),
                amountFeeInFiat?.fiatAmountFormattedString(
                    roundingMode: .down,
                    customFormattForLessThan1E_2: true
                )
            )],
            image: .accountCreationFee,
            info: feeTokens == nil ? nil : { [weak self] in self?.feePrompt.send(feeTokens ?? []) },
            isLoading: isLoading
        )
    }

    private func extractTotalCellModel(state: SendInputState) -> CellModel {
        var subtitles: [(String, String?)] = []

        var totalAmount: Lamports = state.amountInToken.toLamport(decimals: state.token.decimals)
        if state.token.mintAddress == state.tokenFee.mintAddress {
            totalAmount += state.feeInToken.total
        } else {
            let fee = state.feeInToken.transaction + state.feeInToken.accountBalances
            if fee > 0 {
                subtitles.append(convert(fee, state.tokenFee, state.feeWallet?.price))
            }
        }

        subtitles.insert(convert(totalAmount, state.token, state.sourceWallet?.price), at: 0)

        return CellModel(
            type: .total,
            title: L10n.total,
            subtitle: subtitles,
            image: .totalSend
        )
    }

    private func convert(_ input: Lamports, _ token: SolanaAccount, _ price: TokenPrice?) -> (String, String?) {
        let amountInToken: Double = input.convertToBalance(decimals: token.decimals)

        let amountInFiat: Double?
        if let price = price?.doubleValue {
            amountInFiat = amountInToken * price
        } else {
            amountInFiat = nil
        }

        return (
            amountInToken.tokenAmountFormattedString(
                symbol: token.symbol,
                maximumFractionDigits: Int(token.decimals),
                roundingMode: .down
            ),
            amountInFiat?.fiatAmountFormattedString(roundingMode: .down, customFormattForLessThan1E_2: true)
        )
    }

    private func updateCells(for state: SendInputState) {
        cellModels = [
            CellModel(
                type: .address,
                title: L10n.recipientSAddress,
                subtitle: [(state.recipient.address, nil)],
                image: .recipientAddress
            ),
            CellModel(
                type: .recipientGets,
                title: L10n.recipientGets,
                subtitle: [convert(
                    state.amountInToken.toLamport(decimals: state.token.decimals),
                    state.token,
                    state.sourceWallet?.price
                )],
                image: .recipientGet
            ),
            extractTransactionFeeCellModel(state: state),
            accountCreationFeeCellModel,
            extractTotalCellModel(state: state),
        ].compactMap { $0 }
    }
}

private extension SendTransactionDetailViewModel {
    func copyToClipboard(address: String) {
        clipboardManager.copyToClipboard(address)
        notificationsService.showToast(title: "🖤", text: L10n.addressWasCopiedToClipboard, haptic: true)
    }
}

extension SendTransactionDetailViewModel {
    enum CellType: String {
        case address
        case recipientGets
        case transactionFee
        case accountCreationFee
        case total
    }

    struct CellModel: Identifiable {
        let type: CellType
        let title: String
        let subtitle: [(String, String?)]
        let image: ImageResource
        var isFree: Bool = false
        var info: (() -> Void)?
        var isLoading: Bool = false

        var id: String { type.rawValue }
    }
}
