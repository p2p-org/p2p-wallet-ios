//
//  ProfileVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation

class ProfileVC: WLCenterSheet {
    override var padding: UIEdgeInsets {.init(all: 20)}
    
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubviews([
            UIView.row([
                .spacer,
                UILabel(text: L10n.profile, textSize: 17, weight: .bold),
                UIButton(label: L10n.done, labelFont: .systemFont(ofSize: 17), textColor: .secondary)
                    .onTap(self, action: #selector(doneButtonDidTouch))
            ]).with(alignment: .fill, distribution: .equalCentering),
            
            createCell(text: L10n.backup, descriptionView: UIImageView(width: 17, height: 21, image: .backupShield, tintColor: .secondary)),
            
            createCell(text: L10n.network, descriptionView: UILabel(text: SolanaSDK.network, textSize: 15, weight: .medium, textColor: .secondary)),
            
            createCell(text: L10n.security, descriptionView: UILabel(text: "Face ID, Pin", textSize: 15, weight: .medium, textColor: .secondary)),
            
            UIButton(label: L10n.logout, labelFont: .systemFont(ofSize: 15), textColor: .secondary)
                .onTap(self, action: #selector(buttonLogoutDidTouch))
        ])
    }
    
    // MARK: - Actions
    @objc func buttonLogoutDidTouch() {
        showAlert(title: L10n.logout, message: L10n.doYouReallyWantToLogout, buttonTitles: ["OK", L10n.cancel], highlightedButtonIndex: 1) { (index) in
            if index == 0 {
                AccountStorage.shared.clear()
                AppDelegate.shared.reloadRootVC()
            }
        }
    }
    
    @objc func doneButtonDidTouch() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    private func createCell(text: String, descriptionView: UIView) -> UIStackView
    {
        let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 44, height: 44, backgroundColor: .secondary, cornerRadius: 22),
            UILabel(text: text, textSize: 15),
            descriptionView,
            UIImageView(width: 4.5, height: 9, image: .nextArrow, tintColor: .textBlack)
        ])
        stackView.setCustomSpacing(12, after: descriptionView)
        return stackView
    }
}
