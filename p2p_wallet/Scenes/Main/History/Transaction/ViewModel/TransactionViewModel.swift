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
            pricesService: PricesServiceType
        ) {
            let fromView = input.view

            let model = fromView.viewDidLoad
                .mapTo(transaction.mapTransaction(pricesService: pricesService))
            let showWebView = fromView.transactionDetailClicked
                .withLatestFrom(model)
                .map { "https://explorer.solana.com/tx/\($0.transactionId)" }
            let copyTransactionId = fromView.transactionIdClicked
                .withLatestFrom(model)
                .do(onNext: { clipboardManager.copyToClipboard($0.transactionId) })
                .mapToVoid()

            let view = Output.View(
                model: model.asDriver(),
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

    func mapAmounts(pricesService: PricesServiceType) -> (tokens: String?, usd: String?) {
        switch value {
        case let transaction as SolanaSDK.TransferTransaction:
            let fromAmount = transaction.amount?
                .toString(maximumFractionDigits: 9) + " " + transaction.source?.token.symbol
            let toAmount = transaction.destination?.pubkey?.truncatingMiddle() ?? ""
            let usd = "~ " + Defaults.fiat.symbol + getAmountInCurrentFiat(
                pricesService: pricesService,
                amountInToken: transaction.amount,
                symbol: transaction.source?.token.symbol
            ).toString(maximumFractionDigits: 2)
            return (tokens: "\(fromAmount) - \(toAmount)", usd: usd)
        case let transaction as SolanaSDK.SwapTransaction:
            let fromAmount = transaction.sourceAmount?
                .toString(maximumFractionDigits: 9) + " " + transaction.source?.token.symbol
            let toAmount = transaction.destinationAmount?
                .toString(maximumFractionDigits: 9) + " " + transaction.destination?.token.symbol
            let fromUsd = "~ " + Defaults.fiat.symbol + getAmountInCurrentFiat(
                pricesService: pricesService,
                amountInToken: transaction.sourceAmount,
                symbol: transaction.source?.token.symbol
            ).toString(maximumFractionDigits: 2)
            let toUsd = "~ " + Defaults.fiat.symbol + getAmountInCurrentFiat(
                pricesService: pricesService,
                amountInToken: transaction.destinationAmount,
                symbol: transaction.destination?.token.symbol
            ).toString(maximumFractionDigits: 2)
            return (tokens: "\(fromAmount) - \(toAmount)", usd: "\(fromUsd) - \(toUsd)")
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
            let transactionIdClicked = PublishRelay<Void>()
            let doneClicked = PublishRelay<Void>()
            let transactionDetailClicked = PublishRelay<Void>()
        }

        class Coord {}
    }

    struct Output: ViewModelIO {
        typealias Model = History.TransactionView.Model

        let view: View
        let coord: Coord

        struct View {
            var model: Driver<Model>
            var copied: Driver<Void>

            init(
                model: Driver<Model>,
                copied: Driver<Void>
            ) {
                self.model = model
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

// TODO: - Remove after merging 1652

extension ObservableType {
    func filterComplete() -> Observable<Element> {
        materializeAndFilterComplete().dematerialize()
    }

    func materializeAndFilterComplete() -> Observable<RxSwift.Event<Element>> {
        materialize().filter { !$0.event.isCompleted }
    }

    func asDriver() -> RxCocoa.Driver<Element> {
        observe(on: MainScheduler.instance)
            .asDriver(onErrorDriveWith: Driver.empty())
    }

    func mapTo<Result>(_ value: Result) -> Observable<Result> {
        map { _ in value }
    }

    func unwrap<R>() -> Observable<R> where Element == R? {
        compactMap { $0 }
    }

    func optionallWrap() -> Observable<Element?> {
        map { Optional($0) }
    }
}

extension ObservableType {
    func mapToVoid() -> Observable<Void> {
        map { _ in }
    }
}

extension PrimitiveSequence where Trait == SingleTrait {
    func mapToVoid() -> Single<Void> {
        map { _ in }
    }
}

extension ObservableType where Element: EventConvertible {
    /**
     Returns an observable sequence containing only next elements from its input
     - seealso: [materialize operator on reactivex.io](http://reactivex.io/documentation/operators/materialize-dematerialize.html)
     */
    func elements() -> Observable<Element.Element> {
        compactMap(\.event.element)
    }

    /**
     Returns an observable sequence containing only error elements from its input
     - seealso: [materialize operator on reactivex.io](http://reactivex.io/documentation/operators/materialize-dematerialize.html)
     */
    func errors() -> Observable<Error> {
        compactMap(\.event.error)
    }
}
