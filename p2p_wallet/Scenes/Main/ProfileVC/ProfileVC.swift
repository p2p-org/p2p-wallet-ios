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

protocol ProfileScenesFactory {
    func makeBackupVC() -> BackupVC
    func makeSelectNetworkVC() -> SelectNetworkVC
    func makeConfigureSecurityVC() -> ConfigureSecurityVC
    func makeSelectLanguageVC() -> SelectLanguageVC
    func makeSelectAppearanceVC() -> SelectAppearanceVC
}

class ProfileVC: ProfileVCBase {
    lazy var backupShieldImageView = UIImageView(width: 17, height: 21, image: .backupShield)
    lazy var secureMethodsLabel = UILabel(weight: .medium, textColor: .textSecondary)
    lazy var activeLanguageLabel = UILabel(weight: .medium, textColor: .textSecondary)
    lazy var appearanceLabel = UILabel(weight: .medium, textColor: .textSecondary)
    lazy var networkLabel = UILabel(weight: .medium, textColor: .textSecondary)
    lazy var hideZeroBalancesSwitcher: UISwitch = { [unowned self] in
        let switcher = UISwitch()
        switcher.onTintColor = .h5887ff
        switcher.addTarget(self, action: #selector(switcherDidSwitch(sender:)), for: .valueChanged)
        return switcher
    }()
    
    var disposables = [DefaultsDisposable]()
    let accountStorage: KeychainAccountStorage
    let rootViewModel: RootViewModel
    let scenesFactory: ProfileScenesFactory
    
    init(accountStorage: KeychainAccountStorage, rootViewModel: RootViewModel, scenesFactory: ProfileScenesFactory) {
        self.accountStorage = accountStorage
        self.scenesFactory = scenesFactory
        self.rootViewModel = rootViewModel
    }
    
    deinit {
        disposables.forEach {$0.dispose()}
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        
        stackView.addArrangedSubviews([
            createCell(
                image: .settingsBackup,
                text: L10n.backup,
                descriptionView: backupShieldImageView
            )
                .withTag(1)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(
                image: .settingsNetwork,
                text: L10n.network,
                descriptionView: networkLabel
            )
                .withTag(2)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(
                image: .settingsSecurity,
                text: L10n.security,
                descriptionView: secureMethodsLabel
            )
                .withTag(3)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(
                image: .settingsLanguage,
                text: L10n.language,
                descriptionView: activeLanguageLabel
            )
                .withTag(4)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(
                image: .settingsAppearance,
                text: L10n.appearance,
                descriptionView: appearanceLabel
            )
                .withTag(5)
                .onTap(self, action: #selector(cellDidTouch(_:))),
            
            createCell(
                image: .visibilityHide,
                text: L10n.hideZeroBalances,
                descriptionView: hideZeroBalancesSwitcher,
                showRightArrow: false
            ),
            
            BEStackViewSpacing(10),
            
            createCell(
                image: .settingsLogout,
                text: L10n.logout
            )
                .onTap(self, action: #selector(buttonLogoutDidTouch))
        ])
        
        setUpBackupShield()
        
        setUp(enabledBiometry: Defaults.isBiometryEnabled)
        
        setUp(endpoint: Defaults.apiEndPoint)
        
        setUp(theme: AppDelegate.shared.window?.overrideUserInterfaceStyle)
        
        setUp(isZeroBalanceHidden: Defaults.hideZeroBalances)
        
        activeLanguageLabel.text = Locale.current.uiLanguageLocalizedString?.uppercaseFirst
    }
    
    override func bind() {
        super.bind()
        
        disposables.append(Defaults.observe(\.isBiometryEnabled) { update in
            self.setUp(enabledBiometry: update.newValue)
        })
        
        disposables.append(Defaults.observe(\.apiEndPoint){ update in
            self.setUp(endpoint: update.newValue)
        })
    }
    
    func setUpBackupShield() {
        var shieldColor = UIColor.alertOrange
        if accountStorage.didBackupUsingIcloud
        {
            shieldColor = .attentionGreen
        }
        backupShieldImageView.tintColor = shieldColor
    }
    
    func setUp(enabledBiometry: Bool?) {
        var text = ""
        if enabledBiometry == true {
            text += LABiometryType.current.stringValue + ", "
        }
        text += L10n.pinCode
        secureMethodsLabel.text = text
    }
    
    func setUp(endpoint: SolanaSDK.APIEndPoint?) {
        networkLabel.text = endpoint?.network.cluster
    }
    
    func setUp(theme: UIUserInterfaceStyle?) {
        appearanceLabel.text = theme?.localizedString
    }
    
    func setUp(isZeroBalanceHidden: Bool) {
        hideZeroBalancesSwitcher.isOn = isZeroBalanceHidden
    }
    
    // MARK: - Actions
    @objc func buttonLogoutDidTouch() {
        showAlert(title: L10n.logout, message: L10n.doYouReallyWantToLogout, buttonTitles: ["OK", L10n.cancel], highlightedButtonIndex: 1) { (index) in
            if index == 0 {
                self.dismiss(animated: true) {
                    self.rootViewModel.logout()
                }
            }
        }
    }
    
    @objc func cellDidTouch(_ gesture: UIGestureRecognizer) {
        guard let tag = gesture.view?.tag else {return}
        switch tag {
        case 1:
            let vc = scenesFactory.makeBackupVC()
            vc.backedUpIcloudCompletion = {
                self.setUpBackupShield()
            }
            show(vc, sender: nil)
        case 2:
            let vc = scenesFactory.makeSelectNetworkVC()
            show(vc, sender: nil)
        case 3:
            let vc = scenesFactory.makeConfigureSecurityVC()
            show(vc, sender: nil)
        case 4:
            let vc = scenesFactory.makeSelectLanguageVC()
            show(vc, sender: nil)
        case 5:
            let vc = scenesFactory.makeSelectAppearanceVC()
            show(vc, sender: nil)
        default:
            return
        }
    }
    
    // MARK: - Helpers
    private func createCell(image: UIImage?, text: String, descriptionView: UIView? = nil, showRightArrow: Bool = true) -> UIView
    {
        let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 24, height: 24, image: image, tintColor: .a3a5ba),
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
                UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .textBlack)
            )
        }
        return stackView
            .padding(.init(x: 20, y: 16), backgroundColor: .textWhite)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            setUp(theme: traitCollection.userInterfaceStyle)
        }
    }
    
    @objc func switcherDidSwitch(sender: UISwitch) {
        Defaults.hideZeroBalances.toggle()
    }
}
