//
//  TransactionViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 17.04.2022.
//

import Combine
import Foundation
import SolanaSwift
import TransactionParser
import UIKit

extension History {
    @MainActor
    final class TransactionViewModel {
        let input = Input()
        let output: Output

        init(
            transaction: ParsedTransaction,
            clipboardManager: ClipboardManagerType,
            pricesService: PricesServiceType
        ) {
            let fromView = input.view

            let showWebView = fromView.transactionDetailClicked
                .map { _ in "https://explorer.solana.com/tx/\(transaction.signature ?? "")" }
            let model = fromView.viewDidLoad.map { _ in transaction.mapTransaction(pricesService: pricesService) }
            let copyTransactionId = fromView.transactionIdClicked
                .map { _ in transaction.signature ?? "" }
                .handleEvents(receiveOutput: { clipboardManager.copyToClipboard($0) })
                .map { _ in () }

            let view = Output.View(
                model: model.eraseToAnyPublisher(),
                copied: copyTransactionId.eraseToAnyPublisher()
            )
            let coord = Output.Coord(
                done: fromView.doneClicked.eraseToAnyPublisher(),
                showWebView: showWebView.eraseToAnyPublisher()
            )
            output = Output(view: view, coord: coord)
        }
    }
}

// MARK: - Mappers

private extension ParsedTransaction {
    func mapTransaction(
        pricesService: PricesServiceType
    ) -> History.TransactionView.Model {
        let amounts = mapAmounts(pricesService: pricesService)
        return .init(
            imageType: imageType(),
            amount: amounts.tokens,
            usdAmount: amounts.usd,
            blockTime: blockTime?.string(withFormat: "MMMM dd, yyyy @ HH:mm a") ?? "",
            transactionId: signature?
                .truncatingMiddle(numOfSymbolsRevealed: 9, numOfSymbolsRevealedInSuffix: 9) ?? "",
            addresses: getAddresses(),
            fee: mapFee(),
            status: .init(text: status.label, color: status.indicatorColor),
            blockNumber: "#\(slot ?? 0)"
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

        switch info {
        case let transaction as SwapInfo:
            return (
                imageType: .fromOneToOne(from: transaction.source?.token, to: transaction.destination?.token),
                statusImage: statusImage
            )
        default:
            return (imageType: .oneImage(image: icon), statusImage: statusImage)
        }
    }

    func mapAmounts(pricesService: PricesServiceType) -> (tokens: String?, usd: String?) {
        switch info {
        case let transaction as TransferInfo:
            let fromAmount = transaction.rawAmount?
                .toString(maximumFractionDigits: 9) + " " + transaction.source?.token.symbol
            let usd = "~ " + Defaults.fiat.symbol + getAmountInCurrentFiat(
                pricesService: pricesService,
                amountInToken: transaction.rawAmount,
                symbol: transaction.source?.token.symbol
            ).toString(maximumFractionDigits: 2)
            return (tokens: fromAmount, usd: usd)
        case let transaction as SwapInfo:
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
                tokens: "\(fromAmount) - \(toAmount)",
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
        let transaction = info

        let from: String?
        switch transaction {
        case let transaction as SwapInfo:
            from = transaction.source?.pubkey
        case let transaction as TransferInfo:
            from = transaction.source?.pubkey
        default:
            from = nil
        }

        let to: String?
        switch transaction {
        case let transaction as SwapInfo:
            to = transaction.destination?.pubkey
        case let transaction as TransferInfo:
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
            let viewDidLoad = PassthroughSubject<Void, Never>()
            let transactionIdClicked = PassthroughSubject<Void, Never>()
            let doneClicked = PassthroughSubject<Void, Never>()
            let transactionDetailClicked = PassthroughSubject<Void, Never>()
        }

        class Coord {}
    }

    struct Output: ViewModelIO {
        typealias Model = History.TransactionView.Model

        let view: View
        let coord: Coord

        struct View {
            var model: AnyPublisher<Model, Never>
            var copied: AnyPublisher<Void, Never>

            init(
                model: AnyPublisher<Model, Never>,
                copied: AnyPublisher<Void, Never>
            ) {
                self.model = model
                self.copied = copied
            }
        }

        class Coord {
            var done: AnyPublisher<Void, Never>
            var showWebView: AnyPublisher<String, Never>

            init(
                done: AnyPublisher<Void, Never>,
                showWebView: AnyPublisher<String, Never>
            ) {
                self.done = done
                self.showWebView = showWebView
            }
        }
    }
}
