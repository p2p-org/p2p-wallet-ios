//
//  Settings.BackupViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation
import UIKit

extension Settings {
    class BackupViewController: BaseViewController {
        // MARK: - Properties
        lazy var shieldImageView = UIImageView(width: 80, height: 100, image: .backupShield)
        lazy var titleLabel = UILabel(textSize: 21, weight: .bold, numberOfLines: 0, textAlignment: .center)
        lazy var descriptionLabel = UILabel(textSize: 15, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
        lazy var backupUsingIcloudButton = WLButton.stepButton(enabledColor: .blackButtonBackground.onDarkMode(.h2b2b2b), textColor: .white, label: " " + L10n.backupUsingICloud)
        lazy var backupMannuallyButton = WLButton.stepButton(enabledColor: .f6f6f8.onDarkMode(.h2b2b2b), textColor: .textBlack, label: L10n.backupManually)
        private let dismissAfterBackup: Bool
    
        init(viewModel: SettingsViewModelType, dismissAfterBackup: Bool = false) {
            self.dismissAfterBackup = dismissAfterBackup
            super.init(viewModel: viewModel)
        }
    
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            navigationBar.titleLabel.text = L10n.backup
            view.backgroundColor = .white.onDarkMode(.h1b1b1b)
            
            stackView.spacing = 0
            
            let spacer1 = UIView.spacer
            let spacer2 = UIView.spacer
            stackView.addArrangedSubviews([
                UIView.defaultSeparator(),
                spacer1,
                shieldImageView
                    .centeredHorizontallyView,
                BEStackViewSpacing(30),
                titleLabel
                    .padding(.init(x: 20, y: 0)),
                BEStackViewSpacing(10),
                descriptionLabel
                    .padding(.init(x: 20, y: 0)),
                spacer2,
                backupUsingIcloudButton
                    .onTap(self, action: #selector(buttonBackupUsingICloudDidTouch))
                    .padding(.init(x: 20, y: 0)),
                BEStackViewSpacing(10),
                backupMannuallyButton
                    .onTap(self, action: #selector(buttonBackupManuallyDidTouch))
                    .padding(UIEdgeInsets.init(x: 20, y: 0).modifying(dBottom: 44))
            ])
            
            spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor)
                .isActive = true
        }
        
        override func bind() {
            super.bind()
            viewModel.didBackupDriver
                .drive(onNext: {[weak self] didBackup in
                    self?.handleDidBackup(didBackup)
                })
                .disposed(by: disposeBag)
        }
        
        @objc func buttonBackupUsingICloudDidTouch() {
            viewModel.backupUsingICloud()
        }
        
        @objc func buttonBackupManuallyDidTouch() {
            viewModel.backupManually()
        }
        
        // MARK: - Helpers
        private func handleDidBackup(_ didBackup: Bool) {
            if didBackup && dismissAfterBackup {
                back()
                return
            }
            
            var shieldColor = UIColor.alertOrange
            var title = L10n.yourWalletNeedsBackup
            var subtitle = L10n.ifYouLoseThisDeviceYouCanRecoverYourEncryptedWalletByUsingICloudOrMannuallyInputingYourSecretPhrases
            var isIcloudButtonHidden = false
            var backupMannuallyButtonTitle = L10n.backupManually
            var backupMannuallyButtonTextColor = UIColor.textBlack
            if didBackup {
                shieldColor = .attentionGreen
                title = L10n.yourWalletIsBackedUp
                subtitle = L10n.ifYouLoseThisDeviceYouCanRecoverYourEncryptedWalletBackupFromICloud
                backupMannuallyButtonTitle = L10n.viewRecoveryKey
                backupMannuallyButtonTextColor = .h5887ff
                
                isIcloudButtonHidden = true
            }
            
            self.shieldImageView.tintColor = shieldColor
            self.titleLabel.text = title
            self.descriptionLabel.text = subtitle
            self.backupUsingIcloudButton.isHidden = isIcloudButtonHidden
            self.backupMannuallyButton.setTitle(backupMannuallyButtonTitle, for: .normal)
            self.backupMannuallyButton.setTitleColor(backupMannuallyButtonTextColor, for: .normal)
        }
    }
}
