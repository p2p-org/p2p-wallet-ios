//
//  TransactionDetail.FeesSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2022.
//

import Foundation
import UIKit
import RxSwift
import BEPureLayout
import RxCocoa

extension TransactionDetail {
    final class FeesSection: UIStackView {
        private let disposeBag = DisposeBag()
        private let viewModel: TransactionDetailViewModelType
        
        init(viewModel: TransactionDetailViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill)
            addArrangedSubviews {
                // Separator
                UIView.defaultSeparator()
                
                // Amounts
                BEVStack(spacing: 8) {
                    // Swap
                    swapSection()
                        .setup { receivedView in
                            viewModel.parsedTransactionDriver
                                .map {$0?.value is SolanaSDK.SwapTransaction}
                                .map {!$0}
                                .drive(receivedView.rx.isHidden)
                                .disposed(by: disposeBag)
                        }
                    
                    // Transfer
                    transferSection()
                        .setup { receivedView in
                            viewModel.parsedTransactionDriver
                                .map {$0?.value is SolanaSDK.TransferTransaction}
                                .map {!$0}
                                .drive(receivedView.rx.isHidden)
                                .disposed(by: disposeBag)
                        }
                    
                    // Fee
                    feesSection()
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func swapSection() -> BEVStack {
            let swapTransactionDriver = viewModel.parsedTransactionDriver
                .map {$0?.value as? SolanaSDK.SwapTransaction}
            
            return BEVStack(spacing: 8) {
                BEHStack(spacing: 4) {
                    titleLabel(text: L10n.spent)
                    UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
                        .setup { label in
                            swapTransactionDriver
                                .map { [weak self] swapTransaction -> String? in
                                    self?.getString(amount: swapTransaction?.sourceAmount, symbol: swapTransaction?.source?.token.symbol)
                                }
                                .drive(label.rx.text)
                                .disposed(by: disposeBag)
                        }
                }
                
                BEHStack(spacing: 4) {
                    titleLabel(text: L10n.received)
                    UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
                        .setup { label in
                            swapTransactionDriver
                                .map { [weak self] swapTransaction -> String? in
                                    self?.getString(amount: swapTransaction?.destinationAmount, symbol: swapTransaction?.destination?.token.symbol)
                                }
                                .drive(label.rx.text)
                                .disposed(by: disposeBag)
                        }
                }
            }
        }
        
        private func transferSection() -> BEHStack {
            BEHStack(spacing: 4) {
                titleLabel(text: L10n.spent)
                    .setup { label in
                        viewModel.parsedTransactionDriver
                            .map {$0?.amount ?? 0}
                            .map {$0 > 0 ? L10n.received: L10n.spent}
                            .drive(label.rx.text)
                            .disposed(by: disposeBag)
                    }
                UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
                    .setup { label in
                        viewModel.parsedTransactionDriver
                            .map { [weak self] in
                                self?.getString(amount: $0?.amount, symbol: $0?.symbol)
                            }
                            .drive(label.rx.text)
                            .disposed(by: disposeBag)
                    }
            }
        }
        
        private func feesSection() -> BEHStack {
            let feesAndPayingFeeWalletDriver = viewModel.parsedTransactionDriver
                .map {($0?.fee, ($0?.value as? SolanaSDK.SwapTransaction))}
            
            return BEHStack(spacing: 4) {
                titleLabel(text: L10n.transferFee)
                    .setup { label in
                        viewModel.parsedTransactionDriver
                            .map {$0?.value is SolanaSDK.SwapTransaction}
                            .map {$0 ? L10n.swapFees: L10n.transferFee}
                            .drive(label.rx.text)
                            .disposed(by: disposeBag)
                    }
                
                BEVStack(spacing: 8) {
                    // deposit
                    UILabel(text: "0.02 SOL (Deposit)", textSize: 15, textAlignment: .right)
                        .setup { depositLabel in
                            feesDriver.map {$0?.deposit}
                        }
                }
                
                UILabel(text: "Free (Paid by P2P.org)", textSize: 15, textAlignment: .right)
                    .setup { label in
                        feesDriver
                            .map {feeAmount in
                                
                            }
                            .drive(label.rx.text)
                            .disposed(by: disposeBag)
                    }
            }
        }
        
        private func getString(amount: Double?, symbol: String?) -> String? {
            amount.toString(maximumFractionDigits: 9) + " " + symbol
                + " " +
                "(~\(Defaults.fiat.symbol)\(viewModel.getAmountInCurrentFiat(amountInToken: amount, symbol: symbol) ?? 0))"
        }
    }
}

private func titleLabel(text: String) -> UILabel {
    UILabel(text: text, textSize: 15, textColor: .textSecondary, numberOfLines: 2)
}
