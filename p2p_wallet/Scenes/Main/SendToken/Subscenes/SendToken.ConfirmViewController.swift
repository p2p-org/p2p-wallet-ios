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
        private lazy var receiveSection = createSection(title: L10n.recipient, content: nil)
        private lazy var actionButton = WLStepButton.main(image: .buttonSendSmall, text: L10n.send(amount, tokenSymbol))
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
                    createSection(
                        title: L10n.receive,
                        content: "\(fiatSymbol)\(tokenPrice)"
                    )
                    
                    createSection(
                        title: "1 \(fiatCode)",
                        content: "\(tokenPriceReversed) \(tokenSymbol)"
                    )
                }
                
                UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                    createSection(
                        title: "1 \(tokenSymbol)",
                        content: "\(fiatSymbol)\(tokenPrice)"
                    )
                    
                    createSection(
                        title: "1 \(fiatCode)",
                        content: "\(tokenPriceReversed) \(tokenSymbol)"
                    )
                }
                
                UIView.separator(height: 1, color: .separator)
                
                UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                    createSection(
                        title: L10n.receive,
                        content: nil,
                        contentAttributedString: NSMutableAttributedString()
                            .text("\(amount) \(tokenSymbol)", size: 15, color: .textBlack)
                            .text(" ")
                            .text("(~\(fiatSymbol)\(amountEquityValue))", size: 15, color: .textSecondary)
                    )
                    
                    createSection(
                        title: L10n.transferFee,
                        content: nil,
                        contentAttributedString: NSMutableAttributedString()
                            .text("\(fee)", size: 15, color: .textBlack)
                            .text(" ")
                            .text("(\(feeEquityValue))", size: 15, color: .textSecondary)
                    )
                    
                    createSection(
                        title: L10n.total,
                        content: nil,
                        contentAttributedString: NSMutableAttributedString()
                            .text("\(total) \(tokenSymbol)", size: 15, color: .textBlack)
                            .text(" ")
                            .text("(~\(fiatSymbol)\(totalEquityValue))", size: 15, color: .textSecondary)
                    )
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
            
            // setup
            if viewModel.shouldShowConfirmAlert() {
                var index = 0
                stackView.insertArrangedSubviews(at: &index) {
                    alertBannerView
                    BEStackViewSpacing(8)
                }
            }
            
            if viewModel.getSelectedRecipient()?.name == nil {
                nameLabel.isHidden = true
            }
        }
        
        override func bind() {
            super.bind()
            // title
            viewModel.walletDriver
                .map {L10n.confirmSending($0?.token.symbol ?? "")}
                .drive(navigationBar.titleLabel.rx.text)
                .disposed(by: disposeBag)
            
            // recipient
            viewModel.recipientDriver
                .map {$0?.name}
                .drive(nameLabel.rx.text)
                .disposed(by: disposeBag)
            
            // network
            viewModel.networkDriver
                .drive(
                    with: self,
                    onNext: {`self`, network in
                        self.networkView.setUp(network: network, fee: network.defaultFee, renBTCPrice: self.viewModel.getRenBTCPrice())
                    }
                )
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
                selectedNetwork: viewModel.getSelectedNetwork() ?? .solana
            )
                {[weak self] network in
                    
                }
            show(vc, sender: nil)
        }
        
        // MARK: - Helpers
        private func createSection(title: String?, content: String?, contentAttributedString: NSAttributedString? = nil, contentNumberOfLines: Int? = nil) -> UIStackView {
            let stackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .equalSpacing) {
                createHeaderLabel(text: title)
            }
            
            let contentLabel = createContentLabel(text: content, numberOfLines: contentNumberOfLines)
            if let contentAttributedString = contentAttributedString {
                contentLabel
                    .withAttributedText(contentAttributedString)
            }
            
            stackView.addArrangedSubview(contentLabel)
            
            return stackView
        }
        
        private func createHeaderLabel(text: String?, numberOfLines: Int? = nil) -> UILabel {
            UILabel(text: text, textSize: 15, textColor: .textSecondary, numberOfLines: numberOfLines)
        }
        
        private func createContentLabel(text: String?, numberOfLines: Int? = nil) -> UILabel {
            UILabel(text: text, textSize: 15, numberOfLines: numberOfLines, textAlignment: .right)
        }
        
        // MARK: - Getters
        private var tokenSymbol: String {
            viewModel.getSelectedWallet()?.token.symbol ?? ""
        }
        
        private var tokenPrice: String {
            viewModel.getSelectedTokenPrice().toString(maximumFractionDigits: 9)
        }
        
        private var tokenPriceReversed: String {
            viewModel.getSelectedTokenPrice() == 0 ? "0": (1/viewModel.getSelectedTokenPrice()).toString(maximumFractionDigits: 9)
        }
        
        private var fiatSymbol: String {
            Defaults.fiat.symbol
        }
        
        private var fiatCode: String {
            Defaults.fiat.code
        }
        
        private var amount: String {
            viewModel.getSelectedAmount()?.toString(maximumFractionDigits: 9) ?? ""
        }
        
        private var amountEquityValue: String {
            ((viewModel.getSelectedAmount() ?? 0) * viewModel.getSelectedTokenPrice())
                .toString(maximumFractionDigits: 2)
        }
        
        private var fee: String {
            guard let network = viewModel.getSelectedNetwork() else {return ""}
            switch network {
            case .solana:
                return L10n.free
            case .bitcoin:
                return "\(network.defaultFee.amount.toString(maximumFractionDigits: 9)) \(tokenSymbol)"
            }
        }
        
        private var feeEquityValue: String {
            guard let network = viewModel.getSelectedNetwork() else {return ""}
            switch network {
            case .solana:
                return L10n.paidByP2p
            case .bitcoin:
                return "\(fiatSymbol)\((network.defaultFee.amount * viewModel.getSelectedTokenPrice()).toString(maximumFractionDigits: 2))"
            }
        }
        
        private var total: String {
            (viewModel.getSelectedAmount() + (viewModel.getSelectedNetwork()?.defaultFee.amount ?? 0))
                .toString(maximumFractionDigits: 9)
        }
        
        private var totalEquityValue: String {
            ((viewModel.getSelectedAmount() + (viewModel.getSelectedNetwork()?.defaultFee.amount ?? 0)) * viewModel.getSelectedTokenPrice())
                .toString(maximumFractionDigits: 2)
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
                .text(amountInFiat.toString(maximumFractionDigits: 2), size: 13, weight: .medium)
            
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
        lazy var leftLabel = UILabel(text: "<Receive>", textSize: 15, textColor: .textSecondary)
        lazy var rightLabel = UILabel(text: "<0.00227631 renBTC (~$150)>", textSize: 15, numberOfLines: 0, textAlignment: .right)
        
        init() {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .equalSpacing)
            addArrangedSubviews {
                leftLabel
                rightLabel
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
