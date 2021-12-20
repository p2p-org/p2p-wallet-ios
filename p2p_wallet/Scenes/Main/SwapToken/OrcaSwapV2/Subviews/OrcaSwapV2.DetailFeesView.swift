//
//  OrcaSwapV2.DetailFeesView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.12.2021.
//

import BEPureLayout
import UIKit
import RxSwift
import RxCocoa

extension OrcaSwapV2 {
    final class DetailFeesView: UIStackView {
        private let title = UILabel(
            text: L10n.swapFees,
            textSize: 15,
            weight: .regular,
            textColor: .h8e8e93
        )
        private let feesDescriptionView = UIStackView(
            axis: .vertical,
            spacing: 8,
            alignment: .fill
        )
        
        private let feesDriver: Driver<Loadable<[PayingFee]>>
        private let disposeBag = DisposeBag()

        init(feesDriver: Driver<Loadable<[PayingFee]>>) {
            self.feesDriver = feesDriver
            super.init(frame: .zero)

            layout()
            bind()
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        fileprivate func setUp(fees: [PayingFee]) {
            // clear
            feesDescriptionView.arrangedSubviews.forEach {
                $0.removeFromSuperview()
            }
            
            // liquidity
            let liquidityProviderFees = fees.filter {$0.type == .liquidityProviderFee}
            if liquidityProviderFees.count > 0 {
                let view = createLiquidityProviderFeesLine(fees: liquidityProviderFees)
                feesDescriptionView.addArrangedSubview(view)
            }
            
            // another fees
            fees.filter {$0.type != .liquidityProviderFee}.forEach {
                feesDescriptionView.addArrangedSubview(createFeeLine(fee: $0))
            }
            
            // total fees
            let totalFeesSymbol = fees.first(where: {$0.type == .transactionFee})?.token.symbol
            if let totalFeesSymbol = totalFeesSymbol {
                let totalFees = fees.filter {$0.token.symbol == totalFeesSymbol}
                let decimals = totalFees.first?.token.decimals ?? 0
                let amount = totalFees
                    .reduce(UInt64(0)) { $0 + $1.lamports }
                    .convertToBalance(decimals: decimals)
                    .toString(maximumFractionDigits: Int(decimals)) + " \(totalFeesSymbol)"
                feesDescriptionView.addArrangedSubviews {
                    UIView.defaultSeparator()
                    createFeeLine(amount: amount, type: L10n.totalFees)
                }
            }
            
            setNeedsLayout()
        }

        private func layout() {
            set(axis: .horizontal, spacing: 8, alignment: .top)

            title.autoSetDimension(.height, toSize: 21)
            title.setContentHuggingPriority(.required, for: .horizontal)

            addArrangedSubviews {
                title
                feesDescriptionView
            }
        }
        
        private func bind() {
            feesDriver
                .map {$0.value == nil}
                .drive(rx.isHidden)
                .disposed(by: disposeBag)
            
            feesDriver
                .filter {$0.value != nil}
                .map {$0.value!}
                .drive(rx.fees)
                .disposed(by: disposeBag)
        }

        private func createFeeLine(fee: PayingFee) -> UIView {
            createFeeLine(
                amount: fee.lamports.convertToBalance(decimals: fee.token.decimals)
                    .toString(maximumFractionDigits: Int(fee.token.decimals)) +
                    " \(fee.token.symbol)",
                type: fee.type.headerString
            )
        }
        
        private func createFeeLine(amount: String, type: String) -> UIView {
            UILabel(text: nil, textSize: 15, numberOfLines: 0, textAlignment: .right)
                .withAttributedText(
                    NSMutableAttributedString()
                        .text(amount, size: 15, color: .textBlack)
                        .text(" (\(type))", size: 15, color: .h8e8e93)
                        .withParagraphStyle(lineSpacing: 4, alignment: .right)
                )
        }
        
        private func createLiquidityProviderFeesLine(fees: [PayingFee]) -> UIView {
            UILabel(
                text: nil,
                textSize: 15,
                numberOfLines: 0,
                textAlignment: .right
            )
                .withAttributedText(
                    NSMutableAttributedString()
                        .text(
                            fees.map { fee in
                                let amount = fee.lamports.convertToBalance(decimals: fee.token.decimals)
                                    .toString(maximumFractionDigits: Int(fee.token.decimals))
                                return amount + " " + fee.token.symbol
                            }
                            .joined(separator: " + "),
                            size: 15,
                            color: .textBlack
                        )
                        .text(" (\(PayingFee.FeeType.liquidityProviderFee.headerString))", size: 15, color: .h8e8e93)
                        .withParagraphStyle(lineSpacing: 4, alignment: .right)
                )
        }
    }
}

extension Reactive where Base == OrcaSwapV2.DetailFeesView {
    var fees: Binder<[PayingFee]> {
        Binder(base) {view, value in
            view.setUp(fees: value)
        }
    }
}
