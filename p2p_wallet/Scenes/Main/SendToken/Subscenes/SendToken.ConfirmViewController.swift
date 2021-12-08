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
            UIImageView(width: 24, height: 24, image: .closeBannerButton)
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
        private lazy var transferFeeSection: SectionView = {
            let transferFeeSection = SectionView(title: L10n.transferFee)
            transferFeeSection.addArrangedSubview(freeFeeInfoButton)
            return transferFeeSection
        }()
        private lazy var freeFeeInfoButton = UIImageView(width: 21, height: 21, image: .info, tintColor: .h34c759)
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
                alertBannerView
                
                UIView.floatingPanel {
                    amountView
                }
                
                UIView.floatingPanel {
                    recipientView
                }
                
                UIView.floatingPanel {
                    networkView
                }
                
                BEStackViewSpacing(26)
                
                UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                    receiveSection
                    transferFeeSection
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
                    self.networkView.setUp(network: network, fee: network.defaultFee, renBTCPrice: self.viewModel.getRenBTCPrice())
                })
                .disposed(by: disposeBag)
            
            // receive
            walletAndAmountDriver
                .map {wallet, amount in
                    let amount = amount?.convertToBalance(decimals: wallet?.token.decimals ?? 0)
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
                    switch network {
                    case .solana:
                        return NSMutableAttributedString()
                            .text(L10n.free + " ", size: 15, weight: .semibold)
                            .text("(\(L10n.PaidByP2p.org))", size: 15, color: .h34c759)
                    case .bitcoin:
                        return NSMutableAttributedString()
                            .text(network.defaultFee.amount.toString(maximumFractionDigits: 9), size: 15)
                            .text(" ")
                            .text(network.defaultFee.unit, size: 15)
                            .text(" ("
                                  + Defaults.fiat.symbol
                                  + (network.defaultFee.amount * self?.viewModel.getRenBTCPrice())
                                    .toString(maximumFractionDigits: 2)
                                  + ")",
                                  size: 15,
                                  color: .textSecondary
                            )
                            .text("\n")
                            .text("0.0002 SOL", size: 15)
                            .text(" ("
                                + Defaults.fiat.symbol
                                + (0.0002 * self?.viewModel.getSOLPrice())
                                    .toString(maximumFractionDigits: 2)
                                + ")",
                                size: 15,
                                color: .textSecondary
                            )
                            
                    }
                }
                .drive(transferFeeSection.rightLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            viewModel.networkDriver
                .map {$0 != .solana}
                .drive(freeFeeInfoButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            // action button
            walletAndAmountDriver
                .map { wallet, amount in
                    let amount = amount?.convertToBalance(decimals: wallet?.token.decimals) ?? 0
                    let symbol = wallet?.token.symbol ?? ""
                    return L10n.send(amount.toString(maximumFractionDigits: 9), symbol)
                }
                .drive(actionButton.rx.text)
                .disposed(by: disposeBag)
                
        }
        
        // MARK: - Actions
        @objc private func closeBannerButtonDidTouch() {
            viewModel.closeConfirmAlert()
            UIView.animate(withDuration: 0.3) {
                self.alertBannerView.isHidden = true
            }
        }
        
        @objc private func actionButtonDidTouch() {
            viewModel.authenticateAndSend()
        }
        
        @objc private func networkViewDidTouch() {
            let vc = SelectNetworkViewController(
                selectableNetworks: viewModel.getSelectableNetworks(),
                renBTCPrice: viewModel.getRenBTCPrice(),
                selectedNetwork: viewModel.getSelectedNetwork()
            )
                {[weak self] network in
                    self?.viewModel.selectNetwork(network)
                }
            show(vc, sender: nil)
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
        
        func setUp(wallet: Wallet?, amount: SolanaSDK.Lamports) {
            coinImageView.setUp(wallet: wallet)
            
            let amount = amount.convertToBalance(decimals: wallet?.token.decimals ?? 0)
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
            addressLabel.text = recipient?.address
        }
    }
    
    class SectionView: UIStackView {
        // MARK: - Dependencies
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private lazy var leftLabel = UILabel(text: "<Receive>", textSize: 15, textColor: .textSecondary)
        lazy var rightLabel = UILabel(text: "<0.00227631 renBTC (~$150)>", textSize: 15, numberOfLines: 0, textAlignment: .right)
        
        init(title: String) {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .equalSpacing)
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
