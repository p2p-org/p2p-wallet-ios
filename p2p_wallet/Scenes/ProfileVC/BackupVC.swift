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
            UIImageView(width: 63, height: 77, image: .backupShield, tintColor: .secondary
            )
                .centeredHorizontallyView,
            UILabel(text: L10n.yourWalletNeedsBackup, textSize: 17, weight: .bold, numberOfLines: 0, textAlignment: .center),
            UILabel(text: L10n.ifYouLoseThisDeviceYouCanRecoverYourEncryptedWalletByUsingICloudOrMannuallyInputingYourSecretPhrases, textSize: 17, textColor: .secondary, numberOfLines: 0, textAlignment: .center),
            WLButton.stepButton(type: .main, label: L10n.backupUsingICloud)
                .onTap(self, action: #selector(buttonBackupUsingICloudDidTouch)),
            WLButton.stepButton(type: .sub, label: L10n.backupManually)
        ], withCustomSpacings: [30, 10, 30, 10])
        
        stackView.setCustomSpacing(60, after: stackView.arrangedSubviews.first!)
    }
    
    @objc func buttonBackupUsingICloudDidTouch() {
        guard let account = AccountStorage.shared.account?.phrase else {return}
        AccountStorage.shared.saveICloud(phrases: account.joined(separator: " "))
        UIApplication.shared.showDone(L10n.savedToICloud)
    }
}
