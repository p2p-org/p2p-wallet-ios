//
//  ProcessTransactionVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation
import Action

class ProcessTransactionVC: WLCenterSheet {
    override var padding: UIEdgeInsets {UIEdgeInsets(top: 30, left: 20, bottom: 30, right: 20)}
    
    // MARK: - Properties
    var signature: String?
    
    // MARK: - Subviews
    lazy var imageView = UIImageView(width: 143, height: 137, image: .walletIntro)
    lazy var titleLabel = UILabel(text: L10n.processing + "...", textSize: 17, weight: .semibold)
    lazy var viewInExplorerButton = WLButton.stepButton(type: .sub, label: L10n.viewInBlockchainExplorer)
    
    lazy var goBackToWalletButton = WLButton.stepButton(type: .black, label: L10n.goBackToWallet)
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        stackView.alignment = .center
        processing()
    }
    
    override func bind() {
        super.bind()
        TransactionsManager.shared.transactions
            .map {$0.first(where: {$0.signature == self.signature})}
            .filter {$0 != nil}
            .subscribe(onNext: {[weak self] transaction in
                self?.showTransactionDetail(transaction!)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Modifiers
    private func processing() {
        stackView.spacing = 48
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        stackView.addArrangedSubviews([
            .separator(height: 20),
            imageView.padding(UIEdgeInsets(x: 30, y: 0)),
            titleLabel.padding(UIEdgeInsets(x: 30, y: 0)),
            .separator(height: 20)
        ])
        forceResizeModal()
    }
    
    private func showTransactionDetail(_ transaction: Transaction)
    {
        stackView.spacing = 0
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        
        titleLabel.text = transaction.amount.toString(maximumFractionDigits: 9, showPlus: true) + " " + transaction.symbol
        
        let statusLabel = UILabel(text: transaction.status.localizedString, textSize: 12, weight: .bold, textColor: UIColor.black.withAlphaComponent(0.5)
        )
        
        let separator = UIView.separator(height: 1, color: .c4c4c4)
        
        let transactionIdLabel = UILabel(text: L10n.transactionID, textSize: 12, weight: .medium, textColor: .textSecondary)
        
        let transactionIdRow = UIView.row([
            UILabel(text: transaction.signature, textSize: 15, weight: .medium),
            {
                var copyToClipboardButton = UIButton(width: 24, height: 24)
                copyToClipboardButton.setImage(.copyToClipboard, for: .normal)
                copyToClipboardButton.tintColor = .textBlack
                copyToClipboardButton.rx.action = CocoaAction {
                    UIApplication.shared.copyToClipboard(transaction.signature)
                    return .just(())
                }
                return copyToClipboardButton
            }()
        ])
        
        let separator2 = UIView.separator(height: 1, color: .c4c4c4)
        
        stackView.addArrangedSubviews([
            .separator(height: 20),
            imageView,
            titleLabel,
            statusLabel.padding(UIEdgeInsets(x: 16, y: 5), backgroundColor: .c4c4c4, cornerRadius: 8),
            separator,
            transactionIdLabel,
            transactionIdRow,
            separator2,
            viewInExplorerButton,
            goBackToWalletButton
        ])
        
        stackView.stretchArrangedSubviews([
            separator,
            transactionIdLabel,
            transactionIdRow,
            separator2,
            viewInExplorerButton,
            goBackToWalletButton
        ])
        
        stackView.setCustomSpacing(30, after: imageView)
        stackView.setCustomSpacing(20, after: titleLabel)
        stackView.setCustomSpacing(16, after: statusLabel.wrapper!)
        stackView.setCustomSpacing(20, after: separator)
        stackView.setCustomSpacing(5, after: transactionIdLabel)
        stackView.setCustomSpacing(20, after: transactionIdRow)
        stackView.setCustomSpacing(20, after: separator2)
        stackView.setCustomSpacing(10, after: viewInExplorerButton)
        
        forceResizeModal()
    }
    
    // MARK: - PresentationControllerDelegate
    override func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = super.presentationController(forPresented: presented, presenting: presenting, source: source) as! DimmingPresentationController
        // disable dismissing on dimmingView
        pc.dimmingView.gestureRecognizers?.forEach {pc.dimmingView.removeGestureRecognizer($0)}
        return pc
    }
}
