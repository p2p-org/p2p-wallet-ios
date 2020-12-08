//
//  TransactionInfoVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/12/2020.
//

import Foundation

class TransactionInfoVC: BaseVStackVC {
    // MARK: - Properties
    override var padding: UIEdgeInsets {.init(top: 0, left: 0, bottom: 20, right: 0)}
    let transaction: Transaction
    
    // MARK: - Initializers
    init(transaction: Transaction) {
        self.transaction = transaction
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        
        // remove top constraint
        scrollView.constraintToSuperviewWithAttribute(.top)?
            .isActive = false
        
        // add header
        let headerView = UIStackView(axis: .horizontal, spacing: 16, alignment: .top, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 44, height: 44, cornerRadius: 22, image: .transactionInfoIcon),
            .col([
                UILabel(text: L10n.transaction, textSize: 17, weight: .bold),
                UILabel(text: transaction.timestamp?.string(withFormat: "dd MMM yyyy @ hh:mm a"), textSize: 15, weight: .medium, textColor: .secondary)
            ]),
            UIButton.close()
                .onTap(self, action: #selector(back))
        ])
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .bottom)
        headerView.autoPinEdge(.bottom, to: .top, of: scrollView, withOffset: -20)
        
        // setup content
        var fromPubkey: String?
        var toPubkey: String?
        if let from = transaction.from {
            fromPubkey = "0x" + from.prefix(4) + "..." + from.suffix(4)
        }
        
        if let to = transaction.to {
            toPubkey = "0x" + to.prefix(4) + "..." + to.suffix(4)
        }
        
        stackView.addArrangedSubviews([
            UILabel(text: transaction.amount?.toString(maximumFractionDigits: 9, showPlus: true), textSize: 25, weight: .bold)
                .padding(.init(x: 20, y: 0)),
            UIView.row([
                UILabel(text: transaction.status.localizedString, textSize: 12, weight: .bold, textColor: .secondary)
                    .padding(.init(x: 16, y: 8), backgroundColor: .buttonSub, cornerRadius: 10),
                .spacer
            ])
                .with(distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            
            separator(),
            
            sectionTitle(L10n.blockNumber),
            sectionContent("\(transaction.slot ?? 0)"),
            
            separator(),
            
            sectionTitle(L10n.transactionID),
            UIView.row([
                UILabel(text: transaction.signature, textSize: 15, weight: .semibold, numberOfLines: 0),
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .textBlack)
                    .onTap(self, action: #selector(buttonCopySignatureToClipboardDidTouch))
            ])
                .with(distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            
            separator(),
            
            sectionTitle(L10n.fee),
            sectionContent(transaction.fee.toString(maximumFractionDigits: 9) + " " + transaction.symbol),
            
            separator(),
            
            sectionTitle(L10n.from),
            UIView.row([
                UIView(width: 55, height: 55, backgroundColor: .c4c4c4, cornerRadius: 55/2),
                UILabel(text: fromPubkey, textSize: 15, weight: .semibold),
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .textBlack)
                    .onTap(self, action: #selector(buttonCopyFromPubkeyDidTouch))
            ])
                .with(spacing: 16, distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            
            separator(),
            
            sectionTitle(L10n.to),
            UIView.row([
                UIView(width: 55, height: 55, backgroundColor: .c4c4c4, cornerRadius: 55/2),
                UILabel(text: toPubkey, textSize: 15, weight: .semibold),
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .textBlack)
                    .onTap(self, action: #selector(buttonCopyToPubkeyDidTouch))
            ])
                .with(spacing: 16, distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            
            separator(),
            
            WLButton.stepButton(type: .sub, label: L10n.viewInBlockchainExplorer)
                .onTap(self, action: #selector(buttonViewInExplorerDidTouch))
                .padding(.init(x: 20, y: 0))
        ], withCustomSpacings: [16, 30, 20, 10, 20, 20, 10, 20, 20, 10, 20, 20, 16, 20, 20, 16, 20, 30])
    }
    
    // MARK: - Actions
    @objc func buttonCopySignatureToClipboardDidTouch() {
        UIApplication.shared.copyToClipboard(transaction.signature)
    }
    
    @objc func buttonCopyFromPubkeyDidTouch() {
        guard let string = transaction.from else {return}
        UIApplication.shared.copyToClipboard(string)
    }
    
    @objc func buttonCopyToPubkeyDidTouch() {
        guard let string = transaction.to else {return}
        UIApplication.shared.copyToClipboard(string)
    }
    
    @objc func buttonViewInExplorerDidTouch() {
        guard let signature = transaction.signature else {return}
        showWebsite(url: "https://explorer.solana.com/tx/" + signature)
    }
    
    // MARK: - View builders
    fileprivate func separator() -> UIView {
        .separator(height: 1, color: UIColor.textBlack.withAlphaComponent(0.1))
    }
    
    fileprivate func sectionTitle(_ title: String?) -> UIView {
        UILabel(text: title, textSize: 12, weight: .semibold, textColor: .secondary)
            .padding(.init(x: 20, y: 0))
    }
    
    fileprivate func sectionContent(_ content: String?) -> UIView {
        UILabel(text: content, textSize: 15, weight: .semibold)
            .padding(.init(x: 20, y: 0))
    }
}

extension TransactionInfoVC: UIViewControllerTransitioningDelegate {
    class PresentationController: CustomHeightPresentationController {
        override func containerViewDidLayoutSubviews() {
            super.containerViewDidLayoutSubviews()
            presentedView?.roundCorners([.topLeft, .topRight], radius: 20)
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(height: {
            if UIDevice.current.userInterfaceIdiom == .phone, UIDevice.current.orientation == .landscapeLeft ||
                UIDevice.current.orientation == .landscapeRight
            {
                return UIScreen.main.bounds.height
            }
            return UIScreen.main.bounds.height - 85.adaptiveHeight
        }, presentedViewController: presented, presenting: presenting)
    }
}
