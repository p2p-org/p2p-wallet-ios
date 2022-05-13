//
//  TransactionViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 17.04.2022.
//

import Alamofire
import Foundation
import RxCocoa
import RxSwift
import SolanaSwift
import UIKit

extension History {
    final class TransactionViewModel {
        let input = Input()
        let output: Output

        init(
            transaction: SolanaSDK.ParsedTransaction,
            clipboardManager: ClipboardManagerType,
            pricesService: PricesServiceType,
            transactionHandler: TransactionHandlerType
        ) {
            let fromView = input.view

            let showWebView = fromView.transactionDetailClicked
                .mapTo("https://explorer.solana.com/tx/\(transaction.signature ?? "")")
            let model = fromView.viewDidLoad
                .mapTo(transaction.mapTransaction(pricesService: pricesService))
            let tokenAmount = transaction.mapAmounts(pricesService: pricesService).token ?? ""
            let tryAgainState = fromView.tryAgain
                .compactMap { transaction.rawTransaction }
                .map { (transaction: $0.transaction, sentAt: $0.sentAt) }
                .flatMapLatest {
                    transactionHandler.sendAgainTransaction(sentAt: $0.sentAt, rawTransaction: $0.transaction)
                }
                .compactMap { $0?.status }
            let copyTransactionId = fromView.transactionIdClicked
                .mapTo(transaction.signature ?? "")
                .do(onNext: { clipboardManager.copyToClipboard($0) })
                .mapToVoid()

            let state: Observable<Output.State> = .merge(
                model.map { .single(model: $0) },
                fromView.tryAgain.map {
                    .pending(model: Output.PendingModel(
                        state: .pending,
                        amount: tokenAmount,
                        transactionId: transaction.signature?.formattedTransactionId ?? ""
                    ))
                },
                tryAgainState.withLatestFrom(model) { ($0, $1) }.map { state, model in
                    switch state {
                    case .sending, .confirmed:
                        return .pending(model: Output.PendingModel(
                            state: .pending,
                            amount: tokenAmount,
                            transactionId: transaction.signature?.formattedTransactionId ?? ""
                        ))
                    case .finalized:
                        return .pending(model: Output.PendingModel(
                            state: .success,
                            amount: tokenAmount,
                            transactionId: transaction.signature?.formattedTransactionId ?? ""
                        ))
                    case .error:
                        return .single(model: model)
                    }
                }
            )
            let mergedStates = Observable<Output.State>.merge(
                state,
                fromView.viewWillAppear.withLatestFrom(state)
            )

            let view = Output.View(
                state: mergedStates.asDriver(),
                copied: copyTransactionId.asDriver()
            )
            let coord = Output.Coord(
                done: fromView.doneClicked.asDriver(),
                showWebView: showWebView.asDriver()
            )
            output = Output(view: view, coord: coord)
        }
    }
}

// MARK: - Mappers

private extension SolanaSDK.ParsedTransaction {
    func mapTransaction(
        pricesService: PricesServiceType
    ) -> History.TransactionView.Model {
        let amounts = mapAmounts(pricesService: pricesService)
        var tryAgain = false
        if case .error = status {
            tryAgain = true
        }
        return .init(
            imageType: imageType(),
            amount: amounts.token,
            usdAmount: amounts.usd,
            blockTime: blockTime?.string(withFormat: "MMMM dd, yyyy @ HH:mm a") ?? "",
            transactionId: signature?.formattedTransactionId ?? "",
            addresses: getAddresses(),
            fee: mapFee(),
            status: .init(text: status.label, color: status.indicatorColor),
            blockNumber: "#\(slot ?? 0)",
            tryAgain: tryAgain
        )
    }

    func imageType() -> (imageType: TransactionImageView.ImageType, statusImage: UIImage?) {
        var statusImage: UIImage?
        switch status {
        case .requesting, .processing:
            statusImage = .transactionIndicatorPending
        case .error:
            statusImage = .transactionIndicatorError
        default:
            break
        }

        switch value {
        case let transaction as SolanaSDK.SwapTransaction:
            return (
                imageType: .fromOneToOne(from: transaction.source?.token, to: transaction.destination?.token),
                statusImage: statusImage
            )
        default:
            return (imageType: .oneImage(image: icon), statusImage: statusImage)
        }
    }

    func mapAmounts(pricesService: PricesServiceType) -> (token: String?, usd: String?) {
        switch value {
        case let transaction as SolanaSDK.TransferTransaction:
            let fromAmount = transaction.amount?
                .toString(maximumFractionDigits: 9) + " " + transaction.source?.token.symbol
            let usd = "~ " + Defaults.fiat.symbol + getAmountInCurrentFiat(
                pricesService: pricesService,
                amountInToken: transaction.amount,
                symbol: transaction.source?.token.symbol
            ).toString(maximumFractionDigits: 2)
            return (token: fromAmount, usd: usd)
        case let transaction as SolanaSDK.SwapTransaction:
            let fromAmount = transaction.sourceAmount?
                .toString(maximumFractionDigits: 9) + " " + transaction.source?.token.symbol
            let toAmount = transaction.destinationAmount?
                .toString(maximumFractionDigits: 9) + " " + transaction.destination?.token.symbol
            let usd = max(
                getAmountInCurrentFiat(
                    pricesService: pricesService,
                    amountInToken: transaction.sourceAmount,
                    symbol: transaction.source?.token.symbol
                ) ?? 0,
                getAmountInCurrentFiat(
                    pricesService: pricesService,
                    amountInToken: transaction.destinationAmount,
                    symbol: transaction.destination?.token.symbol
                ) ?? 0
            )
            return (
                token: "\(fromAmount) - \(toAmount)",
                usd: "~ \(Defaults.fiat.symbol)\(usd.toString(maximumFractionDigits: 2))"
            )
        default:
            return (nil, nil)
        }
    }

    func getAmountInCurrentFiat(
        pricesService: PricesServiceType,
        amountInToken: Double?,
        symbol: String?
    ) -> Double? {
        guard let amountInToken = amountInToken,
              let symbol = symbol,
              let price = pricesService.currentPrice(for: symbol)?.value
        else { return nil }
        return amountInToken * price
    }

    func getAddresses() -> (from: String?, to: String?) {
        let transaction = value

        let from: String?
        switch transaction {
        case let transaction as SolanaSDK.SwapTransaction:
            from = transaction.source?.pubkey
        case let transaction as SolanaSDK.TransferTransaction:
            from = transaction.source?.pubkey
        default:
            from = nil
        }

        let to: String?
        switch transaction {
        case let transaction as SolanaSDK.SwapTransaction:
            to = transaction.destination?.pubkey
        case let transaction as SolanaSDK.TransferTransaction:
            to = transaction.destination?.pubkey
        default:
            to = nil
        }

        return (
            from: from?.truncatingMiddle(numOfSymbolsRevealed: 9, numOfSymbolsRevealedInSuffix: 9),
            to: to?.truncatingMiddle(numOfSymbolsRevealed: 9, numOfSymbolsRevealedInSuffix: 9)
        )
    }

    func mapFee() -> NSAttributedString? {
        let payingWallet = Wallet.nativeSolana(pubkey: nil, lamport: 0)
        let feeAmount = fee

        let amount = feeAmount?.accountBalances.convertToBalance(decimals: payingWallet.token.decimals) ?? 0
        let transferAmount = feeAmount?.transaction.convertToBalance(decimals: payingWallet.token.decimals) ?? 0
        let swapFee = ((feeAmount?.transaction ?? 0) + (feeAmount?.accountBalances ?? 0))
            .convertToBalance(decimals: payingWallet.token.decimals)

        if amount == 0, transferAmount == 0, swapFee == 0 {
            return NSMutableAttributedString().text(L10n.FreeByP2p.org, size: 16, color: ._4d77ff)
        } else {
            return NSMutableAttributedString().text(
                max(amount, transferAmount, swapFee)
                    .toString(maximumFractionDigits: 9) + " " + payingWallet.token.symbol,
                size: 15,
                color: .textSecondary
            )
        }
    }
}

// MARK: - ViewModel

extension History.TransactionViewModel: ViewModel {
    struct Input: ViewModelIO {
        let view = View()
        let coord = Coord()

        struct View {
            let viewDidLoad = PublishRelay<Void>()
            let viewWillAppear = PublishRelay<Void>()
            let transactionIdClicked = PublishRelay<Void>()
            let doneClicked = PublishRelay<Void>()
            let transactionDetailClicked = PublishRelay<Void>()
            let tryAgain = PublishRelay<Void>()
        }

        class Coord {}
    }

    struct Output: ViewModelIO {
        typealias Model = History.TransactionView.Model
        typealias PendingModel = History.TransactionPendingView.Model

        enum State {
            case single(model: Model)
            case pending(model: PendingModel)
        }

        let view: View
        let coord: Coord

        struct View {
            var state: Driver<State>
            var copied: Driver<Void>

            init(
                state: Driver<State>,
                copied: Driver<Void>
            ) {
                self.state = state
                self.copied = copied
            }
        }

        class Coord {
            var done: Driver<Void>
            var showWebView: Driver<String>

            init(
                done: Driver<Void>,
                showWebView: Driver<String>
            ) {
                self.done = done
                self.showWebView = showWebView
            }
        }
    }
}

private extension String {
    var formattedTransactionId: String {
        truncatingMiddle(numOfSymbolsRevealed: 9, numOfSymbolsRevealedInSuffix: 9)
    }
}
