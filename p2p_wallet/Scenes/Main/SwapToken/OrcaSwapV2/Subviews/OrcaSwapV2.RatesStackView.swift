//
//  OrcaSwapV2.RatesStackView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.12.2021.
//

import BEPureLayout
import RxCocoa
import RxSwift
import UIKit

extension OrcaSwapV2 {
    final class RatesStackView: UIStackView {
        // MARK: - Properties

        private let disposeBag = DisposeBag()
        private let exchangeRateDriver: Driver<Double?>
        private let sourceWalletDriver: Driver<Wallet?>
        private let destinationWalletDriver: Driver<Wallet?>

        // MARK: - Subviews

        private let fromRatesView = DetailRatesView()
        private let toRatesView = DetailRatesView()

        init(
            exchangeRateDriver: Driver<Double?>,
            sourceWalletDriver: Driver<Wallet?>,
            destinationWalletDriver: Driver<Wallet?>
        ) {
            self.exchangeRateDriver = exchangeRateDriver
            self.sourceWalletDriver = sourceWalletDriver
            self.destinationWalletDriver = destinationWalletDriver
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 8, alignment: .fill)
            layout()
            bind()
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func layout() {
            addArrangedSubviews {
                fromRatesView.padding(.init(x: 0, y: 3))
                toRatesView.padding(.init(x: 0, y: 3))
            }
        }

        private func bind() {
            exchangeRateDriver
                .withLatestFrom(
                    Driver.combineLatest(
                        sourceWalletDriver,
                        destinationWalletDriver
                    ),
                    resultSelector: { ($0, $1.0, $1.1) }
                )
                .map { rate, source, destination -> RateRowContent? in
                    guard let rate = rate,
                          let source = source,
                          let destination = destination
                    else {
                        return nil
                    }

                    let sourceSymbol = source.token.symbol
                    let destinationSymbol = destination.token.symbol

                    let fiatPrice = source.priceInCurrentFiat
                        .toString(maximumFractionDigits: 2)
                    let formattedFiatPrice = "(~\(Defaults.fiat.symbol)\(fiatPrice))"

                    return .init(
                        token: sourceSymbol,
                        price: "\(rate.toString(maximumFractionDigits: 9)) \(destinationSymbol)",
                        fiatPrice: formattedFiatPrice
                    )
                }
                .drive { [weak fromRatesView] in
                    fromRatesView?.isHidden = $0 == nil

                    if let rateContent = $0 {
                        fromRatesView?.setData(content: rateContent)
                    }
                }
                .disposed(by: disposeBag)

            exchangeRateDriver
                .map { $0.isNilOrZero ? nil : 1 / $0 }
                .withLatestFrom(
                    Driver.combineLatest(
                        sourceWalletDriver,
                        destinationWalletDriver
                    ),
                    resultSelector: { ($0, $1.0, $1.1) }
                )
                .map { rate, source, destination -> RateRowContent? in
                    guard let rate = rate,
                          let source = source,
                          let destination = destination
                    else {
                        return nil
                    }

                    let sourceSymbol = source.token.symbol
                    let destinationSymbol = destination.token.symbol

                    let fiatPrice = destination.priceInCurrentFiat
                        .toString(maximumFractionDigits: 2)
                    let formattedFiatPrice = "(~\(Defaults.fiat.symbol)\(fiatPrice))"

                    return .init(
                        token: destinationSymbol,
                        price: "\(rate.toString(maximumFractionDigits: 9)) \(sourceSymbol)",
                        fiatPrice: formattedFiatPrice
                    )
                }
                .drive { [weak toRatesView] in
                    toRatesView?.isHidden = $0 == nil

                    if let rateContent = $0 {
                        toRatesView?.setData(content: rateContent)
                    }
                }
                .disposed(by: disposeBag)
        }
    }

    private final class DetailRatesView: BEView {
        private let horizontalLabelsWithSpacer = HorizontalLabelsWithSpacer()

        init() {
            super.init(frame: .zero)

            horizontalLabelsWithSpacer.configureLeftLabel { label in
                label.textColor = .h8e8e93
                label.font = .systemFont(ofSize: 15, weight: .regular)
            }

            layout()
        }

        func setData(content: RateRowContent) {
            horizontalLabelsWithSpacer.configureLeftLabel { label in
                label.text = L10n._1Price(content.token)
            }

            horizontalLabelsWithSpacer.configureRightLabel { label in
                label.attributedText = NSMutableAttributedString()
                    .text(content.price, size: 15, color: .textBlack)
                    .text(" \(content.fiatPrice)", size: 15, color: .h8e8e93)
            }
        }

        private func layout() {
            addSubview(horizontalLabelsWithSpacer)
            horizontalLabelsWithSpacer.autoPinEdgesToSuperviewEdges()
        }
    }
}
