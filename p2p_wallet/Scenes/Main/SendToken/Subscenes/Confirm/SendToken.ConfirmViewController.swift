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
        
        // MARK: - Subviews
        private lazy var alertBannerView = UIView.greyBannerView(axis: .horizontal, spacing: 18, alignment: .top) {
            UILabel(text: L10n.BeSureAllDetailsAreCorrectBeforeConfirmingTheTransaction.onceConfirmedItCannotBeReversed, textSize: 15, numberOfLines: 0)
            UIView.closeBannerButton()
                .onTap(self, action: #selector(closeBannerButtonDidTouch))
        }
        
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
                                viewModel.payingWalletDriver,
                                viewModel.feeInfoDriver
                            )
                                .drive(onNext: { [weak self, weak view] network, payingWallet, feeInfo in
                                    guard let self = self else {return}
                                    view?.setUp(
                                        network: network,
                                        payingWallet: payingWallet,
                                        feeInfo: feeInfo.value,
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
                        payingWalletDriver: viewModel.payingWalletDriver,
                        feeInfoDriver: viewModel.feeInfoDriver
                    )
                        .setup {view in
                            Driver.combineLatest(
                                viewModel.networkDriver,
                                viewModel.feeInfoDriver
                            )
                                .map {network, fee in
                                    if network != .solana {return true}
                                    if let fee = fee.value?.feeAmount {
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
                UIStackView(axis: .vertical, spacing: 12, alignment: .fill, distribution: .fill) {
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
                    
                    // Fees
                    FeesView(viewModel: viewModel) { [weak self] title, message in
                        self?.showAlert(
                            title: title,
                            message: message,
                            buttonTitles: [L10n.ok],
                            highlightedButtonIndex: 0,
                            completion: nil
                        )
                    }
                }
                
                BEStackViewSpacing(18)
                
                UIView.defaultSeparator()
                
                // Prices
                UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                    SectionView(title: "<1 USD>")
                        .setup { view in
                            view.leftLabel.text = "1 \(Defaults.fiat.code)"
                            viewModel.walletDriver
                                .map {[weak self] in
                                    (self?.viewModel.getPrice(for: $0?.token.symbol ?? ""),
                                     $0?.token.symbol ?? "")
                                }
                                .map { price, symbol in
                                    let price: Double = price == 0 ? 0: 1/price
                                    return price.toString(maximumFractionDigits: 9) + " " + symbol
                                }
                                .drive(view.rightLabel.rx.text)
                                .disposed(by: disposeBag)
                        }
                    
                    SectionView(title: "<1 renBTC>")
                        .setup { view in
                            viewModel.walletDriver
                                .map {$0?.token.symbol ?? ""}
                                .map {"1 \($0)"}
                                .drive(view.leftLabel.rx.text)
                                .disposed(by: disposeBag)
                            
                            viewModel.walletDriver
                                .map {[weak self] in
                                    (self?.viewModel.getPrice(for: $0?.token.symbol ?? ""),
                                     $0?.token.symbol ?? "")
                                }
                                .map {price, _ in
                                    return price?.toString(maximumFractionDigits: 9) + " " + Defaults.fiat.code
                                }
                                .drive(view.rightLabel.rx.text)
                                .disposed(by: disposeBag)
                        }
                }
            }
            
            let scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: .init(top: 8, left: 18, bottom: 18, right: 18))
            scrollView.contentView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
            
            view.addSubview(scrollView)
            scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            scrollView.autoPinEdge(toSuperviewEdge: .leading)
            scrollView.autoPinEdge(toSuperviewEdge: .trailing)
            
            let actionButton = WLStepButton.main(image: .buttonSendSmall, text: L10n.sendNow)
                .setup {view in
                    Driver.combineLatest(
                        viewModel.walletDriver,
                        viewModel.amountDriver
                    )
                        .map { wallet, amount in
                            let amount = amount ?? 0
                            let symbol = wallet?.token.symbol ?? ""
                            return L10n.send(amount.toString(maximumFractionDigits: 9), symbol)
                        }
                        .drive(view.rx.text)
                        .disposed(by: disposeBag)
                    
                    Driver.combineLatest([
                        viewModel.walletDriver.map {$0 != nil},
                        viewModel.amountDriver.map {$0 != nil},
                        viewModel.recipientDriver.map {$0 != nil}
                    ])
                        .map {$0.allSatisfy {$0}}
                        .drive(view.rx.isEnabled)
                        .disposed(by: disposeBag)
                }
                .onTap {[weak self] in
                    self?.viewModel.authenticateAndSend()
                }
            
            view.addSubview(actionButton)
            actionButton.autoPinEdge(.top, to: .bottom, of: scrollView, withOffset: 8)
            actionButton.autoPinEdgesToSuperviewSafeArea(with: .init(all: 18), excludingEdge: .top)
        }
        
        override func bind() {
            super.bind()
            // title
            viewModel.walletDriver
                .map {L10n.confirmSending($0?.token.symbol ?? "")}
                .drive(navigationBar.titleLabel.rx.text)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func closeBannerButtonDidTouch() {
            viewModel.closeConfirmAlert()
            UIView.animate(withDuration: 0.3) {
                self.alertBannerView.isHidden = true
            }
        }
    }
}
