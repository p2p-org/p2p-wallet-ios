//
//  SendToken.ConfirmViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/12/2021.
//

import Foundation
import BEPureLayout
import UIKit
import RxSwift
import RxCocoa

extension SendToken {
    final class ConfirmViewController: BaseViewController {
        // MARK: - Dependencies
        private let viewModel: SendTokenViewModelType
        
        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var alertBannerView = UIView.greyBannerView(axis: .horizontal, spacing: 18, alignment: .top) {
            UILabel(text: L10n.BeSureAllDetailsAreCorrectBeforeConfirmingTheTransaction.onceConfirmedItCannotBeReversed, textSize: 15, numberOfLines: 0)
            UIView.closeBannerButton()
                .onTap(self, action: #selector(closeBannerButtonDidTouch))
        }
        
        private lazy var totalSection = SectionView(title: L10n.total)
        private lazy var tokenToFiatSection = SectionView(title: "<1 renBTC>")
        private lazy var fiatToTokenSection = SectionView(title: "<1 USD>")
        
        private lazy var actionButton = WLStepButton.main(image: .buttonSendSmall, text: L10n.sendNow)
            .onTap(self, action: #selector(actionButtonDidTouch))
        
        // MARK: - Initializer
        init(viewModel: SendTokenViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            
            // layout
            let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                // Alert banner
                if viewModel.shouldShowConfirmAlert() {
                    alertBannerView
                }
                
                // Amount
                UIView.floatingPanel {
                    AmountSummaryView()
                        .setup { view in
                            view.addArrangedSubview(.defaultNextArrow())
                            Driver.combineLatest(
                                viewModel.walletDriver,
                                viewModel.amountDriver
                            )
                                .drive(with: view, onNext: {view, param in
                                    view.setUp(wallet: param.0, amount: param.1 ?? 0)
                                })
                                .disposed(by: disposeBag)
                        }
                }
                    .onTap { [weak self] in
                        self?.viewModel.navigate(to: .chooseTokenAndAmount(showAfterConfirmation: true))
                    }
                
                // Recipient
                UIView.floatingPanel {
                    RecipientView()
                        .setup { view in
                            view.addArrangedSubview(.defaultNextArrow())
                            viewModel.recipientDriver
                                .drive(with: view, onNext: { view, recipient in
                                    view.setUp(recipient: recipient)
                                })
                                .disposed(by: disposeBag)
                        }
                }
                    .onTap { [weak self] in
                        self?.viewModel.navigate(to: .chooseRecipientAndNetwork(showAfterConfirmation: true, preSelectedNetwork: nil))
                    }
                
                // Network
                UIView.floatingPanel {
                    NetworkView()
                        .setup { view in
                            view.addArrangedSubview(.defaultNextArrow())
                            Driver.combineLatest(
                                viewModel.networkDriver,
                                viewModel.feesDriver
                            )
                                .drive(with: view, onNext: { view, params in
                                    view.setUp(
                                        network: params.0,
                                        feeAmount: params.1,
                                        prices: self.viewModel.getSOLAndRenBTCPrices()
                                    )
                                })
                                .disposed(by: disposeBag)
                        }
                }
                    .onTap { [weak self] in
                        self?.viewModel.navigate(to: .chooseNetwork)
                    }
                
                // Paying fee token
                if viewModel.relayMethod == .relay {
                    FeeView(
                        solPrice: viewModel.getPrice(for: "SOL"),
                        feesDriver: viewModel.feesDriver,
                        payingWalletDriver: viewModel.payingWalletDriver,
                        payingWalletStatusDriver: viewModel.payingWalletStatusDriver
                    )
                        .setup {view in
                            Driver.combineLatest(
                                viewModel.networkDriver,
                                viewModel.feesDriver
                            )
                                .map {network, fee in
                                    if network != .solana {return true}
                                    if let fee = fee {
                                        return fee.total == 0
                                    } else {
                                        return true
                                    }
                                }
                                .drive(view.rx.isHidden)
                                .disposed(by: disposeBag)
                        }
                        .onTap { [weak self] in
                            self?.viewModel.navigate(to: .chooseRecipientAndNetwork(showAfterConfirmation: true, preSelectedNetwork: nil))
                        }
                }
                
                BEStackViewSpacing(18)
                
                // Fee sections
                UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                    // Receive
                    SectionView(title: L10n.receive)
                        .setup { view in
                            Driver.combineLatest(
                                viewModel.walletDriver,
                                viewModel.amountDriver
                            )
                                .map {wallet, amount in
                                    let amount = amount
                                    let amountInFiat = amount * wallet?.priceInCurrentFiat.orZero
                                    
                                    return NSMutableAttributedString()
                                        .text(
                                            "\(amount.toString(maximumFractionDigits: 9)) \(wallet?.token.symbol ?? "") ",
                                            size: 15
                                        )
                                        .text("(~\(Defaults.fiat.symbol)\(amountInFiat.toString(maximumFractionDigits: 2)))", size: 15, color: .textSecondary)
                                }
                                .drive(view.rightLabel.rx.attributedText)
                                .disposed(by: disposeBag)
                        }
                    
                    // Transfer fee
                    UIStackView(axis: .horizontal, spacing: 4, alignment: .top, distribution: .fill) {
                        // fee
                        SectionView(title: L10n.transferFee)
                            .setup { view in
                                Driver.combineLatest(
                                    viewModel.networkDriver,
                                    viewModel.feesDriver
                                )
                                    .map {[weak self] network, feeAmount in
                                        guard let self = self else {return NSAttributedString()}
                                        switch network {
                                        case .solana:
                                            return NSMutableAttributedString()
                                                .text(L10n.free + " ", size: 15, weight: .semibold)
                                                .text("(\(L10n.PaidByP2p.org))", size: 15, color: .h34c759)
                                        case .bitcoin:
                                            guard let feeAmount = feeAmount else {return NSAttributedString()}
                                            return feeAmount.attributedString(prices: self.viewModel.getSOLAndRenBTCPrices())
                                                .withParagraphStyle(lineSpacing: 8, alignment: .right)
                                        }
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
                            }
                            .onTap(self, action: #selector(freeFeeInfoButtonDidTouch))
                    }
                    UIStackView(axis: .horizontal) {
                        UIView.spacer
                        UIView.defaultSeparator()
                            .frame(width: 246, height: 1)
                    }
                    totalSection
                }
                
                BEStackViewSpacing(18)
                
                UIView.defaultSeparator()
                
                UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                    fiatToTokenSection
                    tokenToFiatSection
                }
            }
            
            let scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: .init(top: 8, left: 18, bottom: 18, right: 18))
            scrollView.contentView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
            
            view.addSubview(scrollView)
            scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            scrollView.autoPinEdge(toSuperviewEdge: .leading)
            scrollView.autoPinEdge(toSuperviewEdge: .trailing)
            
            view.addSubview(actionButton)
            actionButton.autoPinEdge(.top, to: .bottom, of: scrollView, withOffset: 8)
            actionButton.autoPinEdgesToSuperviewSafeArea(with: .init(all: 18), excludingEdge: .top)
        }
        
        override func bind() {
            super.bind()
            let walletAndAmountDriver = Driver.combineLatest(
                viewModel.walletDriver,
                viewModel.amountDriver
            )
            
            // title
            viewModel.walletDriver
                .map {L10n.confirmSending($0?.token.symbol ?? "")}
                .drive(navigationBar.titleLabel.rx.text)
                .disposed(by: disposeBag)
                    
            // total
            viewModel.feesDriver
                .map {[weak self] feeAmount -> NSAttributedString in
                    guard let self = self, let feeAmount = feeAmount else {return NSAttributedString()}
                    return feeAmount.attributedString(prices: self.viewModel.getSOLAndRenBTCPrices())
                        .withParagraphStyle(lineSpacing: 8, alignment: .right)
                }
                .drive(totalSection.rightLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            // prices
            let priceDriver = viewModel.walletDriver
                .map {[weak self] in
                    (self?.viewModel.getPrice(for: $0?.token.symbol ?? ""),
                     $0?.token.symbol ?? "")
                }
            
            // fiat to token
            fiatToTokenSection.leftLabel.text = "1 \(Defaults.fiat.code)"
            
            priceDriver
                .map { price, symbol in
                    let price: Double = price == 0 ? 0: 1/price
                    return price.toString(maximumFractionDigits: 9) + " " + symbol
                }
                .drive(fiatToTokenSection.rightLabel.rx.text)
                .disposed(by: disposeBag)
            
            // token to fiat
            viewModel.walletDriver
                .map {$0?.token.symbol ?? ""}
                .map {"1 \($0)"}
                .drive(tokenToFiatSection.leftLabel.rx.text)
                .disposed(by: disposeBag)
            
            priceDriver
                .map {price, _ in
                    return price?.toString(maximumFractionDigits: 9) + " " + Defaults.fiat.code
                }
                .drive(tokenToFiatSection.rightLabel.rx.text)
                .disposed(by: disposeBag)
            
            // action button
            walletAndAmountDriver
                .map { wallet, amount in
                    let amount = amount ?? 0
                    let symbol = wallet?.token.symbol ?? ""
                    return L10n.send(amount.toString(maximumFractionDigits: 9), symbol)
                }
                .drive(actionButton.rx.text)
                .disposed(by: disposeBag)
            
            Driver.combineLatest([
                viewModel.walletDriver.map {$0 != nil},
                viewModel.amountDriver.map {$0 != nil},
                viewModel.recipientDriver.map {$0 != nil}
            ])
                .map {$0.allSatisfy {$0}}
                .drive(actionButton.rx.isEnabled)
                .disposed(by: disposeBag)
                
        }
        
        // MARK: - Actions
        @objc private func closeBannerButtonDidTouch() {
            viewModel.closeConfirmAlert()
            UIView.animate(withDuration: 0.3) {
                self.alertBannerView.isHidden = true
            }
        }
        
        @objc private func freeFeeInfoButtonDidTouch() {
            let title: String
            let message: String
            switch viewModel.relayMethod {
            case .reward:
                title = L10n.free.uppercaseFirst
                message = L10n.WillBePaidByP2p.orgWeTakeCareOfAllTransfersCosts
            case .relay:
                title = L10n.thereAreFreeTransactionsLeftForToday(100)
                message = L10n.OnTheSolanaNetworkTheFirst100TransactionsInADayArePaidByP2P.Org.subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee
            }
            showAlert(
                title: title,
                message: message,
                buttonTitles: [L10n.ok],
                highlightedButtonIndex: 0,
                completion: nil
            )
        }
        
        @objc private func actionButtonDidTouch() {
            viewModel.authenticateAndSend()
        }
    }
}
