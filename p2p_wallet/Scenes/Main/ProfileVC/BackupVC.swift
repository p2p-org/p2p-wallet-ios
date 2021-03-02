//
//  BackupVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation

protocol BackupScenesFactory {
    func makeBackupManuallyVC() -> BackupManuallyVC
}

class BackupVC: ProfileVCBase {
    let accountStorage: KeychainAccountStorage
    let scenesFactory: BackupScenesFactory
    
    init(accountStorage: KeychainAccountStorage, scenesFactory: BackupScenesFactory) {
        self.accountStorage = accountStorage
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    override func setUp() {
        title = L10n.backup
        super.setUp()
        stackView.addArrangedSubviews([
            UIImageView(width: 63, height: 77, image: .backupShield, tintColor: .textSecondary
            )
                .centeredHorizontallyView,
            BEStackViewSpacing(30),
            UILabel(text: L10n.yourWalletNeedsBackup, textSize: 17, weight: .bold, numberOfLines: 0, textAlignment: .center),
            BEStackViewSpacing(10),
            UILabel(text: L10n.ifYouLoseThisDeviceYouCanRecoverYourEncryptedWalletByUsingICloudOrMannuallyInputingYourSecretPhrases, textSize: 17, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center),
            BEStackViewSpacing(30),
            WLButton.stepButton(type: .black, label: L10n.backupUsingICloud)
                .onTap(self, action: #selector(buttonBackupUsingICloudDidTouch)),
            BEStackViewSpacing(10),
            WLButton.stepButton(type: .sub, label: L10n.backupManually)
                .onTap(self, action: #selector(buttonBackupManuallyDidTouch))
        ])
        
        stackView.setCustomSpacing(60, after: stackView.arrangedSubviews.first!)
    }
    
    @objc func buttonBackupUsingICloudDidTouch() {
        guard let account = accountStorage.account?.phrase else {return}
        presentLocalAuthVC(accountStorage: accountStorage) { [weak self] in
            self?.accountStorage.saveICloud(phrases: account.joined(separator: " "))
            UIApplication.shared.showDone(L10n.savedToICloud)
        }
    }
    
    @objc func buttonBackupManuallyDidTouch() {
        presentLocalAuthVC(accountStorage: accountStorage) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let vc = self?.scenesFactory.makeBackupManuallyVC()
                else {return}
                self?.show(vc, sender: nil)
            }
        }
    }
    
    override func buttonDoneDidTouch() {
        back()
    }
}
