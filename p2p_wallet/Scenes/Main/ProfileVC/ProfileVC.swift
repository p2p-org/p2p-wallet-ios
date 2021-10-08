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
    func makeReserveNameVC(owner: String, handler: ReserveNameHandler) -> ReserveName.ViewController
    func makeBackupVC() -> BackupVC
    func makeSelectFiatVC() -> SelectFiatVC
    func makeSelectNetworkVC() -> SelectNetworkVC
    func makeConfigureSecurityVC() -> ConfigureSecurityVC
    func makeSelectLanguageVC() -> SelectLanguageVC
    func makeSelectAppearanceVC() -> SelectAppearanceVC
}

class ProfileVC: ProfileVCBase {
    // MARK: - Dependencies
    @Injected private var accountStorage: KeychainAccountStorage
    @Injected private var rootViewModel: RootViewModelType
    @Injected private var analyticsManager: AnalyticsManagerType
    
    // MARK: - Properties
    private var disposables = [DefaultsDisposable]()
    private let scenesFactory: ProfileScenesFactory
    private let reserveNameHandler: ReserveNameHandler
    
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
    private lazy var useFreeTransactionsSwitcher: UISwitch = {[unowned self] in
        let switcher = UISwitch()
        switcher.addTarget(self, action: #selector(useFreeTransactionsSwitcherDidSwitch(sender:)), for: .valueChanged)
        return switcher
    }()
    
    // MARK: - Initializer
    init(scenesFactory: ProfileScenesFactory, reserveNameHandler: ReserveNameHandler) {
        self.reserveNameHandler = reserveNameHandler
        self.scenesFactory = scenesFactory
    }
    
    // MARK: - Methods
    override func setUp() {
        title = L10n.settings
        super.setUp()
        
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
        
        setUpUsername()
        
        setUpBackupShield(didBackup: accountStorage.didBackupUsingIcloud || Defaults.didBackupOffline)
        
        setUp(fiat: Defaults.fiat)
        
        setUp(enabledBiometry: Defaults.isBiometryEnabled)
        
        setUp(endpoint: Defaults.apiEndPoint)
        
        setUp(theme: AppDelegate.shared.window?.overrideUserInterfaceStyle)
        
        setUp(isZeroBalanceHidden: Defaults.hideZeroBalances)
        
        setUp(isUsingFreeTransactions: Defaults.useFreeTransaction)
        
        activeLanguageLabel.text = Locale.current.uiLanguageLocalizedString?.uppercaseFirst
    }
    
    override func bind() {
        super.bind()
        
        disposables.append(Defaults.observe(\.forceCloseNameServiceBanner) {[weak self] _ in
            self?.setUpUsername()
        })
        
        disposables.append(Defaults.observe(\.isBiometryEnabled) { [weak self] update in
            self?.setUp(enabledBiometry: update.newValue)
        })
        
        disposables.append(Defaults.observe(\.apiEndPoint){ [weak self] update in
            self?.setUp(endpoint: update.newValue)
        })
        
        disposables.append(Defaults.observe(\.fiat){ [weak self] update in
            self?.setUp(fiat: update.newValue)
        })
    }
    
    func setUpUsername() {
        usernameLabel.textColor = .textSecondary
        guard let name = accountStorage.getName() else {
            usernameLabel.textColor = .alert
            usernameLabel.text = L10n.notYetReserved
            return
        }
        usernameLabel.text = name.withNameServiceSuffix()
    }
    
    func setUpBackupShield(didBackup: Bool) {
        var shieldColor = UIColor.alertOrange
        if didBackup
        {
            shieldColor = .attentionGreen
        }
        backupShieldImageView.tintColor = shieldColor
    }
    
    func setUp(fiat: Fiat?) {
        fiatLabel.text = fiat?.name
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
    
    func setUp(isUsingFreeTransactions: Bool) {
        useFreeTransactionsSwitcher.isOn = isUsingFreeTransactions
    }
    
    // MARK: - Actions
    @objc func buttonLogoutDidTouch() {
        showAlert(title: L10n.logout, message: L10n.doYouReallyWantToLogout, buttonTitles: ["OK", L10n.cancel], highlightedButtonIndex: 1) { [weak self] (index) in
            guard index == 0 else {return}
            self?.analyticsManager.log(event: .settingsLogoutClick)
            self?.dismiss(animated: true) {
                self?.rootViewModel.logout()
            }
        }
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
    
    // MARK: - Helpers
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            setUp(theme: traitCollection.userInterfaceStyle)
        }
    }
    
    @objc func hideZeroBalancesSwitcherDidSwitch(sender: UISwitch) {
        Defaults.hideZeroBalances.toggle()
        analyticsManager.log(event: .settingsHideBalancesClick(hide: Defaults.hideZeroBalances))
    }
    
    @objc func useFreeTransactionsSwitcherDidSwitch(sender: UISwitch) {
        Defaults.useFreeTransaction.toggle()
    }
}
