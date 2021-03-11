//
//  BackupVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation
import RxCocoa

protocol BackupScenesFactory {
    func makeBackupManuallyVC() -> BackupManuallyVC
}

class BackupVC: ProfileVCBase {
    let accountStorage: KeychainAccountStorage
    let scenesFactory: BackupScenesFactory
    
    lazy var isIcloudBackedUp = BehaviorRelay<Bool>(value: accountStorage.didBackupUsingIcloud)
    var backedUpIcloudCompletion: (() -> Void)?
    
    lazy var shieldImageView = UIImageView(width: 63, height: 77, image: .backupShield)
    lazy var titleLabel = UILabel(textSize: 17, weight: .bold, numberOfLines: 0, textAlignment: .center)
    lazy var descriptionLabel = UILabel(textSize: 17, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
    lazy var backupUsingIcloudButton = WLButton.stepButton(type: .black, label: " " + L10n.backupUsingICloud)
    lazy var backupMannuallyButton = WLButton.stepButton(type: .sub, label: L10n.backupManually)
    
    init(accountStorage: KeychainAccountStorage, scenesFactory: BackupScenesFactory) {
        self.accountStorage = accountStorage
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    override func setUp() {
        title = L10n.backup
        super.setUp()
        view.backgroundColor = .textWhite
        
        stackView.removeFromSuperview()
        scrollView.removeFromSuperview()
        
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20), excludingEdge: .top)
        stackView.autoPinEdge(.top, to: .bottom, of: navigationBar)
        
        stackView.spacing = 0
        
        let spacer1 = UIView.spacer
        let spacer2 = UIView.spacer
        stackView.addArrangedSubviews([
            UIView.separator(height: 1, color: .separator),
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
                .padding(.init(x: 20, y: 0))
        ])
        
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor)
            .isActive = true
    }
    
    override func bind() {
        super.bind()
        isIcloudBackedUp
            .subscribe(onNext: {isBackedUp in
                var shieldColor = UIColor.alertOrange
                var title = L10n.yourWalletNeedsBackup
                var subtitle = L10n.ifYouLoseThisDeviceYouCanRecoverYourEncryptedWalletByUsingICloudOrMannuallyInputingYourSecretPhrases
                var isIcloudButtonHidden = false
                var backupMannuallyButtonTitle = L10n.backupManually
                var backupMannuallyButtonTextColor = UIColor.textBlack
                if isBackedUp {
                    shieldColor = .attentionGreen
                    title = L10n.yourWalletIsBackedUp
                    subtitle = L10n.ifYouLoseThisDeviceYouCanRecoverYourEncryptedWalletBackupFromICloud
                    isIcloudButtonHidden = true
                    backupMannuallyButtonTitle = L10n.viewRecoveryKey
                    backupMannuallyButtonTextColor = .h5887ff
                }
                
                self.shieldImageView.tintColor = shieldColor
                self.titleLabel.text = title
                self.descriptionLabel.text = subtitle
                self.backupUsingIcloudButton.isHidden = isIcloudButtonHidden
                self.backupMannuallyButton.setTitle(backupMannuallyButtonTitle, for: .normal)
                self.backupMannuallyButton.setTitleColor(backupMannuallyButtonTextColor, for: .normal)
            })
            .disposed(by: disposeBag)
    }
    
    @objc func buttonBackupUsingICloudDidTouch() {
        guard let account = accountStorage.account?.phrase else {return}
        presentLocalAuthVC(accountStorage: accountStorage) { [weak self] in
            self?.accountStorage.saveICloud(phrases: account.joined(separator: " "))
            self?.isIcloudBackedUp.accept(true)
            self?.backedUpIcloudCompletion?()
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
}
