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
        super.init()
    }
    
    // MARK: - Methods
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.roundCorners([.topLeft, .topRight], radius: 20)
    }
    
    override func setUp() {
        super.setUp()
        // header
        let headerView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
            // type
            UILabel(text: transaction.type?.localizedString, textSize: 21, weight: .medium, textAlignment: .center),
            // timestamp
            UILabel(text: transaction.timestamp?.string(withFormat: "dd MMM yyyy @ hh:mm a"), textSize: 13, weight: .medium, textColor: .textSecondary, textAlignment: .center)
        ])
            .padding(.init(top: 30, left: 20, bottom: 54, right: 20), backgroundColor: .f6f6f8)
        
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        scrollView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        headerView.autoPinEdge(.bottom, to: .top, of: scrollView)
        
        // icon
        let icon = UIImageView(width: 24, height: 24, image: transaction.type?.icon, tintColor: .white)
            .padding(.init(all: 16), backgroundColor: .h5887ff, cornerRadius: 12)
        view.addSubview(icon)
        icon.autoAlignAxis(toSuperviewAxis: .vertical)
        icon.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: -28)
        
        // content inset
        scrollView.contentInset.modify(dTop: 58)
        
        // setup content
        var fromPubkey: String?
        var toPubkey: String?
        if let from = transaction.from {
            fromPubkey = from.prefix(4) + "..." + from.suffix(4)
        }
        
        if let to = transaction.to {
            toPubkey = to.prefix(4) + "..." + to.suffix(4)
        }
        
        stackView.addArrangedSubviews([
            // amount in usd
            UILabel(text: transaction.amountInUSD.toString(maximumFractionDigits: 9, showPlus: true) + "$", textSize: 27, weight: .bold, textAlignment: .center)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(5),
            
            // amount
            UILabel(text: transaction.amount?.toString(maximumFractionDigits: 9, showPlus: true) + " " + transaction.symbol, textSize: 15, weight: .medium, textAlignment: .center)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            
            // status
            UILabel(text: transaction.status.localizedString, textSize: 12, weight: .bold, textColor: .textGreen)
                .padding(.init(x: 16, y: 8), backgroundColor: UIColor.attentionGreen.withAlphaComponent(0.3), cornerRadius: 10)
                .centeredHorizontallyView,
            BEStackViewSpacing(30),
            
            separator(),
            BEStackViewSpacing(20),
            
            // from
            sectionTitle(L10n.from),
            BEStackViewSpacing(20),
            UIView.row([
                UIView(width: 55, height: 55, backgroundColor: .c4c4c4, cornerRadius: 12),
                UILabel(text: fromPubkey, textSize: 15, weight: .semibold),
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .a3a5ba)
                    .padding(.init(all: 6), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                    .onTap(self, action: #selector(buttonCopyFromPubkeyDidTouch))
            ])
                .with(spacing: 16, distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.to),
            BEStackViewSpacing(20),
            UIView.row([
                UIView(width: 55, height: 55, backgroundColor: .c4c4c4, cornerRadius: 12),
                UILabel(text: toPubkey, textSize: 15, weight: .semibold),
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .a3a5ba)
                    .padding(.init(all: 6), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                    .onTap(self, action: #selector(buttonCopyToPubkeyDidTouch))
            ])
                .with(spacing: 16, distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.date),
            BEStackViewSpacing(8),
            sectionContent(transaction.timestamp?.string(withFormat: "MMMM dd, yyyy @ hh:mm a")),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.amount.uppercaseFirst),
            BEStackViewSpacing(8),
            sectionContent(transaction.amount?.toString(maximumFractionDigits: 9, showPlus: true) + " " + transaction.symbol),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.value),
            BEStackViewSpacing(8),
            sectionContent(transaction.amountInUSD.toString(maximumFractionDigits: 9, showPlus: true) + "$"),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.fee),
            BEStackViewSpacing(8),
            sectionContent(transaction.fee.toString(maximumFractionDigits: 9) + " " + transaction.symbol),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.blockNumber),
            BEStackViewSpacing(8),
            sectionContent("#\(transaction.slot ?? 0)"),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.transactionID),
            BEStackViewSpacing(8),
            UIView.row([
                UILabel(text: transaction.signature, textSize: 15, weight: .semibold, numberOfLines: 0),
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .textBlack)
                    .onTap(self, action: #selector(buttonCopySignatureToClipboardDidTouch))
            ])
                .with(distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            WLButton.stepButton(type: .sub, label: L10n.viewInBlockchainExplorer)
                .onTap(self, action: #selector(buttonViewInExplorerDidTouch))
                .padding(.init(x: 20, y: 0))
        ])
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
        UILabel(text: title, textSize: 12, weight: .semibold, textColor: .textSecondary)
            .padding(.init(x: 20, y: 0))
    }
    
    fileprivate func sectionContent(_ content: String?) -> UIView {
        UILabel(text: content, textSize: 15, weight: .semibold)
            .padding(.init(x: 20, y: 0))
    }
}

//extension TransactionInfoVC: UIViewControllerTransitioningDelegate {
//    class PresentationController: CustomHeightPresentationController {
//        override func containerViewDidLayoutSubviews() {
//            super.containerViewDidLayoutSubviews()
//            presentedView?.roundCorners([.topLeft, .topRight], radius: 20)
//        }
//    }
//
//    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
//        PresentationController(height: {
//            if UIDevice.current.userInterfaceIdiom == .phone, UIDevice.current.orientation == .landscapeLeft ||
//                UIDevice.current.orientation == .landscapeRight
//            {
//                return UIScreen.main.bounds.height
//            }
//            return UIScreen.main.bounds.height - 85.adaptiveHeight
//        }, presentedViewController: presented, presenting: presenting)
//    }
//}
