//
//  BackupManuallyVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/12/2020.
//

import Foundation

class BackupManuallyVC: ProfileVCBase {
    
    let phrases: [String]
    init(accountStorage: SolanaSDKAccountStorage) {
        self.phrases = accountStorage.account?.phrase ?? []
    }
    
    override func setUp() {
        title = L10n.securityKeys.uppercaseFirst
        super.setUp()
        
        var cols = [UIStackView]()
        let firstHaftMaxIndex = Int(Double(phrases.count / 2).rounded(.up))
        cols.append(contentsOf: [
            UIStackView(
                axis: .vertical,
                spacing: 16,
                alignment: .fill,
                distribution: .fill,
                arrangedSubviews: phrases[0..<firstHaftMaxIndex].map {UILabel(text: "\(phrases.firstIndex(of: $0)! + 1). \($0)", textSize: 17, weight: .medium)}),
            UIStackView(
                axis: .vertical,
                spacing: 16,
                alignment: .fill,
                distribution: .fill,
                arrangedSubviews: phrases[firstHaftMaxIndex...].map {UILabel(text: "\(phrases.firstIndex(of: $0)! + 1). \($0)", textSize: 17, weight: .medium)})
            
        ])
        
        stackView.addArrangedSubviews([
            UIView.copyToClipboardButton(spacing: 16, tintColor: .textBlack)
                .onTap(self, action: #selector(buttonCopyToClipboardDidTouch))
                .centeredHorizontallyView,
            BEStackViewSpacing(30),
            UIView.row(cols)
                .with(spacing: 50)
                .padding(.init(x: 50, y: 25), backgroundColor: .buttonSub, cornerRadius: 16)
                .centeredHorizontallyView,
            BEStackViewSpacing(30)
        ])
        
        stackView.setCustomSpacing(60, after: stackView.arrangedSubviews.first!)
    }
    
    // MARK: - Actions
    @objc func buttonCopyToClipboardDidTouch() {
        UIApplication.shared.copyToClipboard(phrases.joined(separator: " "))
    }
    
    override func buttonDoneDidTouch() {
        back()
    }
}
