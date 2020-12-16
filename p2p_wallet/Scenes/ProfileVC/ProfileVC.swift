//
//  ProfileVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation

class ProfileVC: ProfileVCBase {
    // MARK: - Methods
    override func setUp() {
        title = L10n.profile
        
        super.setUp()
        stackView.addArrangedSubviews([
            createCell(text: L10n.backup, descriptionView: UIImageView(width: 17, height: 21, image: .backupShield, tintColor: .secondary)
            )
                .withTag(1)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(text: L10n.network, descriptionView: UILabel(text: Defaults.network.cluster, textSize: 15, weight: .medium, textColor: .secondary)
            )
                .withTag(2)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(text: L10n.security, descriptionView: UILabel(text: "Face ID, Pin", textSize: 15, weight: .medium, textColor: .secondary)
            )
                .withTag(3)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            UIButton(label: L10n.logout, labelFont: .systemFont(ofSize: 15), textColor: .secondary)
                .onTap(self, action: #selector(buttonLogoutDidTouch))
        ])
    }
    
    override func createHeaderView() -> UIStackView {
        let headerView = super.createHeaderView()
        headerView.arrangedSubviews.first?.removeFromSuperview()
        headerView.insertArrangedSubview(.spacer, at: 0)
        return headerView
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
    
    @objc func cellDidTouch(_ gesture: UIGestureRecognizer) {
        guard let tag = gesture.view?.tag else {return}
        switch tag {
        case 1:
            show(BackupVC(), sender: nil)
        case 2:
            show(SelectNetworkVC(), sender: nil)
        case 3:
            show(ConfigureSecurityVC(), sender: nil)
        default:
            return
        }
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
