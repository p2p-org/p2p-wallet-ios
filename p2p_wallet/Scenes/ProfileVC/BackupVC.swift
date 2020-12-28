//
//  BackupVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation

class BackupVC: ProfileVCBase {
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
        guard let account = AccountStorage.shared.account?.phrase else {return}
        AccountStorage.shared.saveICloud(phrases: account.joined(separator: " "))
        UIApplication.shared.showDone(L10n.savedToICloud)
    }
    
    @objc func buttonBackupManuallyDidTouch() {
        let localAuthVC = LocalAuthVC()
        localAuthVC.isIgnorable = true
        localAuthVC.useBiometry = false
        localAuthVC.completion = { [weak self] didSuccess in
            if didSuccess {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.show(BackupManuallyVC(), sender: nil)
                }
            }
        }
//        localAuthVC.modalPresentationStyle = .fullScreen
        present(localAuthVC, animated: true, completion: nil)
    }
    
    override func buttonDoneDidTouch() {
        back()
    }
}
