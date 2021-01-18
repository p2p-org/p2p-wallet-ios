//
//  ProfileVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation
import SwiftyUserDefaults
import LocalAuthentication
import SwiftUI

class ProfileVC: ProfileVCBase {
    lazy var secureMethodsLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
    lazy var activeLanguageLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
    lazy var appearanceLabel = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
    var disposables = [DefaultsDisposable]()
    
    deinit {
        disposables.forEach {$0.dispose()}
    }
    
    // MARK: - Methods
    override func setUp() {
        title = L10n.profile
        
        super.setUp()
        
        var subviews: [BEStackViewElement] = [
            createCell(text: L10n.backup, descriptionView: UIImageView(width: 17, height: 21, image: .backupShield, tintColor: .textSecondary)
            )
                .withTag(1)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(text: L10n.network, descriptionView: UILabel(text: Defaults.network.cluster, textSize: 15, weight: .medium, textColor: .textSecondary)
            )
                .withTag(2)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(text: L10n.security, descriptionView: secureMethodsLabel
            )
                .withTag(3)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(text: L10n.language, descriptionView: activeLanguageLabel
            )
                .withTag(4)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            UIButton(label: L10n.logout, labelFont: .systemFont(ofSize: 15), textColor: .textSecondary)
                .onTap(self, action: #selector(buttonLogoutDidTouch))
        ]
        
        if #available(iOS 13.0, *) {
            subviews.insert(
                createCell(
                    text: L10n.appearance,
                    descriptionView: appearanceLabel
                )
                    .withTag(5)
                    .onTap(self, action: #selector(cellDidTouch(_:)))
                ,
                at: 4
            )
            
            appearanceLabel.text = Defaults.appearance.localizedString
        }
        
        stackView.addArrangedSubviews(subviews)
        
        setUp(enabledBiometry: Defaults.isBiometryEnabled)
        
        activeLanguageLabel.text = Locale.current.uiLanguageLocalizedString?.uppercaseFirst
    }
    
    override func bind() {
        super.bind()
        
        disposables.append(Defaults.observe(\.isBiometryEnabled) { (update) in
            self.setUp(enabledBiometry: update.newValue)
        })
    }
    
    func setUp(enabledBiometry: Bool?) {
        var text = ""
        if enabledBiometry == true {
            text += LABiometryType.current.stringValue + ", "
        }
        text += L10n.pinCode
        self.secureMethodsLabel.text = text
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
    
    override func buttonDoneDidTouch() {
        back()
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
        case 4:
            show(SelectLanguageVC(), sender: nil)
        case 5:
            if #available(iOS 13.0, *) {
                show(SelectAppearanceVC(), sender: nil)
            }
        default:
            return
        }
    }
    
    // MARK: - Helpers
    private func createCell(text: String, descriptionView: UIView) -> UIStackView
    {
        let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 44, height: 44, backgroundColor: .textSecondary, cornerRadius: 22),
            UILabel(text: text, textSize: 15),
            descriptionView,
            UIImageView(width: 4.5, height: 9, image: .nextArrow, tintColor: .textBlack)
        ])
        stackView.setCustomSpacing(12, after: descriptionView)
        return stackView
    }
}

@available(iOS 13, *)
struct ProfileVC_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                ProfileVC()
            }
            .previewDevice("iPhone SE (2nd generation)")
        }
    }
}
