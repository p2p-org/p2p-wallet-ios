//
//  TransactionDetail.AmountSection.swift
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
    final class AmountSection: UIStackView {
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
                                .map { [weak self] swapTransaction -> NSAttributedString? in
                                    self?.getAttributedString(amount: swapTransaction?.sourceAmount, symbol: swapTransaction?.source?.token.symbol)
                                }
                                .drive(label.rx.attributedText)
                                .disposed(by: disposeBag)
                        }
                }
                
                BEHStack(spacing: 4) {
                    titleLabel(text: L10n.received)
                    UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
                        .setup { label in
                            swapTransactionDriver
                                .map { [weak self] swapTransaction -> NSAttributedString? in
                                    self?.getAttributedString(amount: swapTransaction?.destinationAmount, symbol: swapTransaction?.destination?.token.symbol)
                                }
                                .drive(label.rx.attributedText)
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
                                self?.getAttributedString(amount: abs($0?.amount ?? 0), symbol: $0?.symbol)
                            }
                            .drive(label.rx.attributedText)
                            .disposed(by: disposeBag)
                    }
            }
        }
        
        private func feesSection() -> BEHStack {
            let feesDriver = viewModel.parsedTransactionDriver
                .map {$0?.fee}
            
            return BEHStack(spacing: 4, alignment: .top) {
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
//                    UILabel(text: "0.02 SOL (Deposit)", textSize: 15, textAlignment: .right)
//                        .setup { depositLabel in
//                            feesDriver
//                                .map { [weak self] feeAmount -> NSAttributedString? in
//                                    guard let self = self else {return nil}
//                                    let payingWallet = self.getPayingFeeWallet()
//                                    let amount = feeAmount?.deposit
//                                        .convertToBalance(decimals: payingWallet.token.decimals)
//                                        .toString(maximumFractionDigits: 9)
//
//                                    return NSMutableAttributedString()
//                                        .text(amount + " " + payingWallet.token.symbol + " ", size: 15, color: .textBlack)
//                                        .text("(\(L10n.deposit))", size: 15, color: .textSecondary)
//                                }
//                                .drive(depositLabel.rx.attributedText)
//                                .disposed(by: disposeBag)
//
//                            feesDriver
//                                .map {$0?.deposit ?? 0}
//                                .map {$0 == 0}
//                                .drive(depositLabel.rx.isHidden)
//                                .disposed(by: disposeBag)
//                        }
                    
                    // account creation fee
                    UILabel(text: "0.02 SOL (BTC Account Creation)", textSize: 15, textAlignment: .right)
                        .setup { accountCreationLabel in
                            feesDriver
                                .map { [weak self] feeAmount -> NSAttributedString? in
                                    guard let self = self else {return nil}
                                    let payingWallet = self.getPayingFeeWallet()
                                    let amount = feeAmount?.accountBalances
                                        .convertToBalance(decimals: payingWallet.token.decimals)
                                        .toString(maximumFractionDigits: 9)
                                    
                                    return NSMutableAttributedString()
                                        .text(amount + " " + payingWallet.token.symbol + " ", size: 15, color: .textBlack)
                                        .text("(\(L10n.accountCreation(""))", size: 15, color: .textSecondary)
                                }
                                .drive(accountCreationLabel.rx.attributedText)
                                .disposed(by: disposeBag)
                            
                            feesDriver
                                .map {$0?.accountBalances ?? 0}
                                .map {$0 == 0}
                                .drive(accountCreationLabel.rx.isHidden)
                                .disposed(by: disposeBag)
                        }
                    
                    // transfer fee
                    BEHStack(spacing: 4) {
                        UILabel(text: "0.02 SOL (Transfer fee)", textSize: 15, textAlignment: .right)
                            .setup { accountCreationLabel in
                                feesDriver
                                    .map { [weak self] feeAmount -> NSAttributedString? in
                                        guard let self = self else {return nil}
                                        let payingWallet = self.getPayingFeeWallet()
                                        let amount = feeAmount?.transaction
                                            .convertToBalance(decimals: payingWallet.token.decimals)
                                            
                                        if amount > 0 {
                                            return NSMutableAttributedString()
                                                .text(amount.toString(maximumFractionDigits: 9) + " " + payingWallet.token.symbol + " ", size: 15, color: .textBlack)
                                                .text("(\(L10n.transferFee))", size: 15, color: .textSecondary)
                                        } else {
                                            return NSMutableAttributedString()
                                                .text(L10n.free + " ", size: 15, weight: .semibold)
                                                .text("(\(L10n.PaidByP2p.org))", size: 15, color: .h34c759)
                                        }
                                    }
                                    .drive(accountCreationLabel.rx.attributedText)
                                    .disposed(by: disposeBag)
                            }
                        UIImageView(width: 21, height: 21, image: .info, tintColor: .h34c759)
                            .setup { infoButton in
                                feesDriver
                                    .map {$0?.transaction != 0}
                                    .drive(infoButton.rx.isHidden)
                                    .disposed(by: disposeBag)
                            }
                    }
                }
            }
        }
        
        private func getAttributedString(amount: Double?, symbol: String?) -> NSAttributedString? {
            NSMutableAttributedString()
                .text(amount.toString(maximumFractionDigits: 9) + " " + symbol, size: 15, color: .textBlack)
                .text(" ")
                .text("(~\(Defaults.fiat.symbol)\(viewModel.getAmountInCurrentFiat(amountInToken: amount, symbol: symbol)?.toString(maximumFractionDigits: 9) ?? "0"))", size: 15, color: .textSecondary)
        }
        
        private func getPayingFeeWallet() -> Wallet {
            viewModel.getPayingFeeWallet() ?? .nativeSolana(pubkey: nil, lamport: 0)
        }
    }
}

private func titleLabel(text: String) -> UILabel {
    UILabel(text: text, textSize: 15, textColor: .textSecondary, numberOfLines: 2)
}
