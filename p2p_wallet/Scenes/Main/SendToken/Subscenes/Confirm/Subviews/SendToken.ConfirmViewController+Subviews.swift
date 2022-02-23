//
//  SendToken.ConfirmViewController+Subviews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/02/2022.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

extension SendToken.ConfirmViewController {
    class AmountSummaryView: UIStackView {
        // MARK: - Subviews
        private lazy var coinImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private lazy var equityValueLabel = UILabel(text: "<Amount: ~$150>")
        private lazy var amountLabel = UILabel(text: "<1 BTC>", textSize: 17, weight: .semibold)
        
        init() {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill)
            addArrangedSubviews {
                coinImageView
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    equityValueLabel
                    amountLabel
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setUp(wallet: Wallet?, amount: Double) {
            coinImageView.setUp(wallet: wallet)
            
            let amount = amount
            let amountInFiat = amount * wallet?.priceInCurrentFiat.orZero
            
            equityValueLabel.attributedText = NSMutableAttributedString()
                .text(L10n.amount.uppercaseFirst + ": ", size: 13, color: .textSecondary)
                .text(Defaults.fiat.symbol + amountInFiat.toString(maximumFractionDigits: 2), size: 13, weight: .medium)
            
            amountLabel.text = amount.toString(maximumFractionDigits: 9)
        }
    }
    
    class RecipientView: UIStackView {
        // MARK: - Subviews
        private lazy var nameLabel = UILabel(text: "<Recipient: a.p2p.sol>")
        private lazy var addressLabel = UILabel(text: "<DkmTQHutnUn9xWmismkm2zSvLQfiEkPQCq6rAXZKJnBw>", textSize: 17, weight: .semibold, numberOfLines: 0)
        
        init() {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill)
            addArrangedSubviews {
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    nameLabel
                    addressLabel
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setUp(recipient: SendToken.Recipient?) {
            nameLabel.isHidden = false
            if let recipientName = recipient?.name {
                nameLabel.attributedText = NSMutableAttributedString()
                    .text(L10n.recipient.uppercaseFirst + ": ", size: 13, color: .textSecondary)
                    .text(recipientName, size: 13, weight: .medium)
            } else {
                nameLabel.isHidden = true
            }
            addressLabel.text = recipient?.address ?? L10n.chooseTheRecipient
        }
    }
    
    class SectionView: UIStackView {
        // MARK: - Subviews
        lazy var leftLabel = UILabel(text: "<Receive>", textSize: 15, textColor: .textSecondary)
        lazy var rightLabel = UILabel(text: "<0.00227631 renBTC (~$150)>", textSize: 15, numberOfLines: 0, textAlignment: .right)
            .withContentHuggingPriority(.required, for: .vertical)
        
        init(title: String) {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 0, alignment: .top, distribution: .equalSpacing)
            addArrangedSubviews {
                leftLabel
                rightLabel
            }
            leftLabel.text = title
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class FeesView: UIStackView {
        private let disposeBag = DisposeBag()
        private let viewModel: SendTokenViewModelType
        private let feeInfoDidTouch: (String, String) -> Void
        
        init(viewModel: SendTokenViewModelType, feeInfoDidTouch: @escaping (String, String) -> Void) {
            self.viewModel = viewModel
            self.feeInfoDidTouch = feeInfoDidTouch
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill)
            layout()
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func layout() {
            addArrangedSubviews {
                // Transfer fee
                UIStackView(axis: .horizontal, spacing: 4, alignment: .top, distribution: .fill) {
                    // fee
                    SectionView(title: L10n.transferFee)
                        .setup { view in
                            viewModel.feeInfoDriver.map {$0.value?.feeAmount}
                                .map {[weak self] feeAmount in
                                    guard let self = self else {return NSAttributedString()}
                                    guard let feeAmount = feeAmount else {return NSAttributedString()}
                                    let prices = self.viewModel.getPrices(for: ["SOL", "renBTC"])
                                    return feeAmount.attributedStringForTransactionFee(solPrice: prices["SOL"])
                                }
                                .do(afterNext: {[weak view] _ in
                                    view?.rightLabel.setNeedsLayout()
                                    view?.layoutIfNeeded()
                                })
                                .drive(view.rightLabel.rx.attributedText)
                                .disposed(by: disposeBag)
                        }
                    // info
                    UIImageView(width: 21, height: 21, image: .info, tintColor: .h34c759)
                        .setup {view in
                            viewModel.networkDriver
                                .map {$0 != .solana}
                                .drive(view.rx.isHidden)
                                .disposed(by: disposeBag)
                            
                            viewModel.getFreeTransactionFeeLimit()
                                .subscribe(onSuccess: {[weak view] limit in
                                    view?.tintColor = limit.currentUsage >= limit.maxUsage ? .textSecondary: .h34c759
                                })
                                .disposed(by: disposeBag)
                        }
                        .onTap(self, action: #selector(feeInfoButtonDidTap))
                }
                
                // Account creation fee, other fees
                SectionView(title: L10n.accountCreationFee)
                    .setup { view in
                        Driver.combineLatest(
                            viewModel.networkDriver,
                            viewModel.feeInfoDriver.map {$0.value?.feeAmount}
                        )
                            .do(afterNext: {[weak view] _ in
                                view?.rightLabel.setNeedsLayout()
                                view?.layoutIfNeeded()
                            })
                            .drive(onNext: { [weak self, weak view] network, feeAmount in
                                guard let self = self else {return}
                                guard let feeAmount = feeAmount else {
                                    view?.isHidden = true
                                    return
                                }
                                let prices = self.viewModel.getPrices(for: ["SOL", "renBTC"])
                                switch network {
                                case .solana:
                                    view?.leftLabel.text = L10n.accountCreationFee
                                    if let attributedString = feeAmount.attributedStringForAccountCreationFee(solPrice: prices["SOL"])
                                    {
                                        view?.rightLabel.attributedText = attributedString
                                    } else {
                                        view?.isHidden = true
                                    }
                                case .bitcoin:
                                    view?.leftLabel.text = ""
                                    view?.rightLabel.attributedText = feeAmount.attributedStringForOtherFees(prices: prices)
                                }
                            })
                            .disposed(by: disposeBag)
                    }
                
                // Separator
                UIStackView(axis: .horizontal) {
                    UIView.spacer
                    UIView.defaultSeparator()
                        .frame(width: 246, height: 1)
                }
                
                // Total fee
                SectionView(title: L10n.total)
                    .setup { view in
                        viewModel.feeInfoDriver.map {$0.value?.feeAmount}
                            .map {[weak self] feeAmount -> NSAttributedString in
                                guard let self = self, let feeAmount = feeAmount else {return NSAttributedString()}
                                return feeAmount.attributedStringForTotalFee(solPrice: self.viewModel.getPrice(for: "SOL"))
                            }
                            .drive(view.rightLabel.rx.attributedText)
                            .disposed(by: disposeBag)
                    }
            }
        }
        
        @objc func feeInfoButtonDidTap() {
            switch viewModel.relayMethod {
            case .reward:
                let title = L10n.free.uppercaseFirst
                let message = L10n.WillBePaidByP2p.orgWeTakeCareOfAllTransfersCosts
                feeInfoDidTouch(title, message)
            case .relay:
                showIndetermineHud()
                viewModel.getFreeTransactionFeeLimit()
                    .subscribe(onSuccess: {[weak self] limit in
                        self?.hideHud()
                        guard let self = self else {return}
                        let title = L10n.thereAreFreeTransactionsLeftForToday(limit.maxUsage-limit.currentUsage)
                        let message = L10n.OnTheSolanaNetworkTheFirstTransactionsInADayArePaidByP2P.Org.subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee(limit.maxUsage)
                        self.feeInfoDidTouch(title, message)
                    }, onFailure: {[weak self] _ in
                        self?.hideHud()
                    })
                    .disposed(by: disposeBag)
            }
        }
    }
}

private extension SolanaSDK.FeeAmount {
    func attributedStringForTransactionFee(solPrice: Double?) -> NSMutableAttributedString {
        if transaction == 0 {
            return NSMutableAttributedString()
                .text(L10n.free + " ", size: 15, weight: .semibold)
                .text("(\(L10n.PaidByP2p.org))", size: 15, color: .h34c759)
        } else {
            let fee = transaction.convertToBalance(decimals: 9)
            return feeAttributedString(fee: fee, unit: "SOL", price: solPrice)
        }
    }
    
    func attributedStringForAccountCreationFee(solPrice: Double?) -> NSMutableAttributedString? {
        guard accountBalances > 0 else {return nil}
        let fee = accountBalances.convertToBalance(decimals: 9)
        return feeAttributedString(fee: fee, unit: "SOL", price: solPrice)
    }
    
    func attributedStringForTotalFee(solPrice: Double?) -> NSMutableAttributedString {
        let fee = total.convertToBalance(decimals: 9)
        return feeAttributedString(fee: fee, unit: "SOL", price: solPrice)
    }
    
    func attributedStringForOtherFees(
        prices: [String: Double],
        attributedSeparator: NSAttributedString = NSAttributedString(string: "\n")
    ) -> NSMutableAttributedString? {
        guard let others = others, !others.isEmpty else {return nil}
        let attributedText = NSMutableAttributedString()
        for (index, fee) in others.enumerated() {
            attributedText
                .append(feeAttributedString(fee: fee.amount, unit: fee.unit, price: prices[fee.unit]))
            if index < others.count - 1 {
                attributedText
                    .append(attributedSeparator)
            }
        }
        return attributedText
    }
}

private func feeAttributedString(fee: Double, unit: String, price: Double?) -> NSMutableAttributedString {
    let feeInFiat = fee * price
    return NSMutableAttributedString()
        .text("\(fee.toString(maximumFractionDigits: 9)) \(unit)", size: 15, color: .textBlack)
        .text(" (~\(Defaults.fiat.symbol)\(feeInFiat.toString(maximumFractionDigits: 2)))", size: 15, color: .textSecondary)
}
