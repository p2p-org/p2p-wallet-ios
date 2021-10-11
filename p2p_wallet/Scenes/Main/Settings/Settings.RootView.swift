//
//  Settings.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import UIKit
import RxSwift

extension Settings {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        @Injected private var viewModel: SettingsViewModelType
        
        // MARK: - Subviews
        private lazy var usernameLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var backupShieldImageView = UIImageView(width: 17, height: 21, image: .backupShield)
        private lazy var fiatLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var secureMethodsLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var activeLanguageLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var appearanceLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var networkLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var hideZeroBalancesSwitcher: UISwitch = { [unowned self] in
            let switcher = UISwitch()
            switcher.addTarget(self, action: #selector(hideZeroBalancesSwitcherDidSwitch(sender:)), for: .valueChanged)
            return switcher
        }()
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        // MARK: - Layout
        private func layout() {
            var languageTitle = L10n.language
            if languageTitle != "Language" {languageTitle += " (Language)"}
            
            stackView.addArrangedSubviews {
                createCell(
                    image: .settingsUsername,
                    text: L10n.username.uppercaseFirst,
                    descriptionView: usernameLabel
                )
                    .withTag(0)
                    .onTap(self, action: #selector(cellDidTouch(_:)))
                
                BEStackViewSpacing(16)
                
                createCell(
                    image: .settingsBackup,
                    text: L10n.backup,
                    descriptionView: backupShieldImageView
                )
                    .withTag(1)
                    .onTap(self, action: #selector(cellDidTouch(_:)))
                
                createCell(
                    image: .settingsCurrency,
                    text: L10n.currency,
                    descriptionView: fiatLabel
                )
                    .withTag(2)
                    .onTap(self, action: #selector(cellDidTouch(_:)))
                
                createCell(
                    image: .settingsNetwork,
                    text: L10n.network,
                    descriptionView: networkLabel
                )
                    .withTag(3)
                    .onTap(self, action: #selector(cellDidTouch(_:)))
                
                createCell(
                    image: .settingsSecurity,
                    text: L10n.security,
                    descriptionView: secureMethodsLabel
                )
                    .withTag(4)
                    .onTap(self, action: #selector(cellDidTouch(_:)))
                
                createCell(
                    image: .settingsLanguage,
                    text: languageTitle,
                    descriptionView: activeLanguageLabel
                )
                    .withTag(5)
                    .onTap(self, action: #selector(cellDidTouch(_:)))
                
                createCell(
                    image: .settingsAppearance,
                    text: L10n.appearance,
                    descriptionView: appearanceLabel
                )
                    .withTag(6)
                    .onTap(self, action: #selector(cellDidTouch(_:)))
                
                createCell(
                    image: .visibilityHide,
                    text: L10n.hideZeroBalances,
                    descriptionView: hideZeroBalancesSwitcher,
                    showRightArrow: false
                )
                
    //            createCell(
    //                image: .settingsFreeTransactions,
    //                text: L10n.useFreeTransactions,
    //                descriptionView: useFreeTransactionsSwitcher,
    //                showRightArrow: false
    //            )
                
                BEStackViewSpacing(16)
                
                createCell(
                    image: .settingsLogout,
                    text: L10n.logout,
                    showRightArrow: false,
                    isAlert: true
                )
                    .onTap(self, action: #selector(buttonLogoutDidTouch))
            }
        }
        
        private func bind() {
            
        }
        
        // MARK: - Action
        @objc func buttonLogoutDidTouch() {
            viewModel.showLogoutAlert()
        }
        
        @objc func cellDidTouch(_ gesture: UIGestureRecognizer) {
            guard let tag = gesture.view?.tag else {return}
            switch tag {
            case 0:
                if accountStorage.getName() == nil {
                    let vc = scenesFactory.makeReserveNameVC(owner: accountStorage.account?.publicKey.base58EncodedString ?? "", handler: reserveNameHandler)
                    show(vc, sender: nil)
                } else {
                    let vc = UsernameVC()
                    show(vc, sender: nil)
                }
                
            case 1:
                let vc = scenesFactory.makeBackupVC()
                vc.didBackupCompletion = { [weak self] didBackup in
                    self?.setUpBackupShield(didBackup: didBackup)
                }
                show(vc, sender: nil)
            case 2:
                let vc = scenesFactory.makeSelectFiatVC()
                show(vc, sender: nil)
            case 3:
                let vc = scenesFactory.makeSelectNetworkVC()
                show(vc, sender: nil)
            case 4:
                let vc = scenesFactory.makeConfigureSecurityVC()
                show(vc, sender: nil)
            case 5:
                let vc = scenesFactory.makeSelectLanguageVC()
                show(vc, sender: nil)
            case 6:
                let vc = scenesFactory.makeSelectAppearanceVC()
                show(vc, sender: nil)
            default:
                return
            }
        }
        
        @objc func hideZeroBalancesSwitcherDidSwitch(sender: UISwitch) {
            viewModel.setHideZeroBalances(sender.isOn)
        }
    }
}


private func createCell(image: UIImage?, text: String, descriptionView: UIView? = nil, showRightArrow: Bool = true, isAlert: Bool = false) -> UIView
{
    let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
        UIView.squareRoundedCornerIcon(image: image, tintColor: isAlert ? .alert: .iconSecondary),
        UILabel(text: text, textSize: 17, numberOfLines: 0)
    ])
    if let descriptionView = descriptionView {
        stackView.addArrangedSubview(
            descriptionView
                .withContentHuggingPriority(.required, for: .horizontal)
        )
    }
    if showRightArrow {
        stackView.addArrangedSubview(
            UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .black.onDarkMode(.h8d8d8d))
        )
    }
    return stackView
        .padding(.init(x: 20, y: 6), backgroundColor: .contentBackground)
}
