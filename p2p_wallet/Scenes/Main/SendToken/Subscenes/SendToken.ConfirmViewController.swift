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
        @Injected private var viewModel: SendTokenViewModelType
        
        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var alertBannerView = UIView.greyBannerView(axis: .horizontal, spacing: 18, alignment: .top) {
            UILabel(text: L10n.BeSureAllDetailsAreCorrectBeforeConfirmingTheTransaction.onceConfirmedItCannotBeReversed, textSize: 15, numberOfLines: 0)
            UIView.closeBannerButton()
                .onTap(self, action: #selector(closeBannerButtonDidTouch))
        }
        private lazy var amountView: AmountSummaryView = {
            let amountView = AmountSummaryView()
            amountView.addArrangedSubview(.defaultNextArrow())
            return amountView
        }()
        private lazy var recipientView: RecipientView = {
            let recipientView = RecipientView()
            recipientView.addArrangedSubview(.defaultNextArrow())
            return recipientView
        }()
        private lazy var networkView: NetworkView = {
            let networkView = NetworkView()
            networkView.addArrangedSubview(.defaultNextArrow())
            return networkView
        }()
        
        private lazy var receiveSection = SectionView(title: L10n.receive)
        private lazy var transferFeeSection = SectionView(title: L10n.transferFee)
        private lazy var freeFeeInfoButton = UIImageView(width: 21, height: 21, image: .info, tintColor: .h34c759)
            .onTap(self, action: #selector(freeFeeInfoButtonDidTouch))
        private lazy var totalSection = SectionView(title: L10n.total)
        
        private lazy var tokenToFiatSection = SectionView(title: "<1 renBTC>")
        private lazy var fiatToTokenSection = SectionView(title: "<1 USD>")
        
        private lazy var actionButton = WLStepButton.main(image: .buttonSendSmall, text: L10n.sendNow)
            .onTap(self, action: #selector(actionButtonDidTouch))
        
        // MARK: - Initializer
        override func setUp() {
            super.setUp()
            
            // layout
            let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                UIView.floatingPanel {
                    amountView
                }
                    .onTap(self, action: #selector(amountViewDidTouch))
                
                UIView.floatingPanel {
                    recipientView
                }
                    .onTap(self, action: #selector(recipientViewDidTouch))
                
                UIView.floatingPanel {
                    networkView
                }
                    .onTap(self, action: #selector(networkViewDidTouch))
                
                BEStackViewSpacing(26)
                
                UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                    receiveSection
                    UIStackView(axis: .horizontal, spacing: 4, alignment: .top, distribution: .fill) {
                        transferFeeSection
                        freeFeeInfoButton
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
            
            // alert
            if viewModel.shouldShowConfirmAlert() {
                stackView.insertArrangedSubview(alertBannerView, at: 0)
            }
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
            
            // amount
            walletAndAmountDriver
                .drive(with: self, onNext: {`self`, param in
                    self.amountView.setUp(wallet: param.0, amount: param.1 ?? 0)
                })
                .disposed(by: disposeBag)
            
            // recipient
            viewModel.recipientDriver
                .drive(with: self, onNext: { `self`, recipient in
                    self.recipientView.setUp(recipient: recipient)
                })
                .disposed(by: disposeBag)
            
            // network view
            viewModel.networkDriver
                .drive(with: self, onNext: { `self`, network in
                    self.networkView.setUp(
                        network: network,
                        prices: self.viewModel.getSOLAndRenBTCPrices()
                    )
                })
                .disposed(by: disposeBag)
            
            // receive
            walletAndAmountDriver
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
                .drive(receiveSection.rightLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            // transfer fee
            viewModel.networkDriver
                .map {[weak self] network in
                    guard let self = self else {return NSAttributedString()}
                    switch network {
                    case .solana:
                        return NSMutableAttributedString()
                            .text(L10n.free + " ", size: 15, weight: .semibold)
                            .text("(\(L10n.PaidByP2p.org))", size: 15, color: .h34c759)
                    case .bitcoin:
                        return network.defaultFees.attributedString(prices: self.viewModel.getSOLAndRenBTCPrices())
                            .withParagraphStyle(lineSpacing: 8, alignment: .right)
                    }
                }
                .drive(transferFeeSection.rightLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            viewModel.networkDriver
                .map {$0 != .solana}
                .do(afterNext: {[weak self] _ in
                    self?.transferFeeSection.rightLabel.setNeedsLayout()
                    self?.transferFeeSection.layoutIfNeeded()
                })
                .drive(freeFeeInfoButton.rx.isHidden)
                .disposed(by: disposeBag)
                    
            // total
            Driver.combineLatest(
                walletAndAmountDriver,
                viewModel.networkDriver
            )
                .map {[weak self] walletAndAmount, network -> NSAttributedString in
                    guard let self = self else {return NSAttributedString()}
                    let amount = walletAndAmount.1 ?? 0
                    let wallet = walletAndAmount.0
                    let symbol = wallet?.token.symbol ?? ""
                    
                    var fees = network.defaultFees
                    
                    if let index = fees.firstIndex(where: {$0.unit == symbol}) {
                        fees[index].amount += amount
                    } else {
                        fees.append(.init(amount: amount, unit: symbol))
                    }
                    
                    fees.removeAll(where: {$0.amount == 0})
                    
                    return fees.attributedString(prices: self.viewModel.getSOLAndRenBTCPrices())
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
        
        @objc private func amountViewDidTouch() {
            viewModel.navigate(to: .chooseTokenAndAmount(showAfterConfirmation: true))
        }
        
        @objc private func recipientViewDidTouch() {
            viewModel.navigate(to: .chooseRecipientAndNetwork(showAfterConfirmation: true, preSelectedNetwork: nil))
        }
        
        @objc private func networkViewDidTouch() {
            viewModel.navigate(to: .chooseNetwork)
        }
        
        @objc private func freeFeeInfoButtonDidTouch() {
            showAlert(
                title: L10n.thereAreFreeTransactionsLeftForToday(100),
                message: L10n.OnTheSolanaNetworkTheFirst100TransactionsInADayArePaidByP2P.Org.subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee,
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

private extension SendToken {
    class AmountSummaryView: UIStackView {
        // MARK: - Dependencies
        private let disposeBag = DisposeBag()
        
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
        // MARK: - Dependencies
        private let disposeBag = DisposeBag()
        
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
        
        func setUp(recipient: Recipient?) {
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
        // MARK: - Dependencies
        private let disposeBag = DisposeBag()
        
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
}
