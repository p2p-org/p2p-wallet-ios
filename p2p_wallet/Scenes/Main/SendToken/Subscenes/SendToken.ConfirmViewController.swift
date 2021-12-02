//
//  SendToken.ConfirmViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/12/2021.
//

import Foundation
import BEPureLayout
import UIKit

extension SendToken {
    final class ConfirmViewController: BaseViewController {
        // MARK: - Dependencies
        private let viewModel: SendTokenViewModelType
        
        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var networkView = NetworkView()
        private lazy var nameLabel = UILabel(text: viewModel.getSelectedRecipient()?.name, textSize: 15, textColor: .textSecondary, textAlignment: .right)
        private lazy var actionButton = WLStepButton.main(image: .buttonSendSmall, text: L10n.send(amount, tokenSymbol))
            .onTap(self, action: #selector(actionButtonDidTouch))
        
        // MARK: - Initializer
        init(viewModel: SendTokenViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            // set up views
            navigationBar.titleLabel.text = L10n.confirmSending(viewModel.getSelectedWallet()?.token.symbol ?? "")
            
            if let network = viewModel.getSelectedNetwork() {
                networkView.setUp(network: network, fee: network.defaultFee, renBTCPrice: viewModel.getRenBTCPrice())
//                networkView.addArrangedSubview(UIView.defaultNextArrow())
            }
            
            // layout
            let stackView = UIStackView(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill) {
                UIView.greyBannerView {
                    UILabel(text: L10n.BeSureAllDetailsAreCorrectBeforeConfirmingTheTransaction.onceConfirmedItCannotBeReversed, textSize: 15, numberOfLines: 0)
                }
                BEStackViewSpacing(8)
                UIView.floatingPanel {
                    networkView
                }
                BEStackViewSpacing(26)
                UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .equalSpacing) {
                    createHeaderLabel(text: L10n.recipientSAddress, numberOfLines: 2)
                    
                    createContentLabel(
                        text: viewModel.getSelectedRecipient()?.address,
                        numberOfLines: 2
                    )
                        .lineBreakMode(.byCharWrapping)
                }
                
                BEStackViewSpacing(8)
                UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fill) {
                    UIView.spacer
                    nameLabel
                }
                
                UIView.separator(height: 1, color: .separator)
                
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
            if viewModel.getSelectedRecipient()?.name == nil {
                nameLabel.isHidden = true
            }
        }
        
        override func bind() {
            super.bind()
            
        }
        
        // MARK: - Actions
        @objc private func actionButtonDidTouch() {
            viewModel.authenticateAndSend()
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
