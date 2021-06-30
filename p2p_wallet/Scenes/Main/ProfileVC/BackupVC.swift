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
    func makeBackupShowPhrasesVC() -> BackupShowPhrasesVC
}

class BackupVC: ProfileVCBase {
    let accountStorage: KeychainAccountStorage
    let authenticationHandler: AuthenticationHandler
    let scenesFactory: BackupScenesFactory
    let analyticsManager: AnalyticsManagerType
    
    lazy var didBackupSubject = BehaviorRelay<Bool>(value: accountStorage.didBackupUsingIcloud || Defaults.didBackupOffline)
    var didBackupCompletion: ((Bool) -> Void)?
    
    lazy var shieldImageView = UIImageView(width: 80, height: 100, image: .backupShield)
    lazy var titleLabel = UILabel(textSize: 21, weight: .bold, numberOfLines: 0, textAlignment: .center)
    lazy var descriptionLabel = UILabel(textSize: 15, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
    lazy var backupUsingIcloudButton = WLButton.stepButton(enabledColor: .blackButtonBackground.onDarkMode(.h2b2b2b), textColor: .white, label: " " + L10n.backupUsingICloud)
    lazy var backupMannuallyButton = WLButton.stepButton(enabledColor: .f6f6f8.onDarkMode(.h2b2b2b), textColor: .textBlack, label: L10n.backupManually)
    
    init(accountStorage: KeychainAccountStorage, authenticationHandler: AuthenticationHandler, scenesFactory: BackupScenesFactory, analyticsManager: AnalyticsManagerType) {
        self.accountStorage = accountStorage
        self.authenticationHandler = authenticationHandler
        self.scenesFactory = scenesFactory
        self.analyticsManager = analyticsManager
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsManager.log(event: .settingBackupOpen)
    }
    
    override func setUp() {
        title = L10n.backup
        super.setUp()
        view.backgroundColor = .white.onDarkMode(.h1b1b1b)
        
        stackView.removeFromSuperview()
        scrollView.removeFromSuperview()
        
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20), excludingEdge: .top)
        stackView.autoPinEdge(.top, to: .bottom, of: navigationBar)
        
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
        didBackupSubject
            .subscribe(onNext: {[weak self] isBackedUp in
                self?.handleDidBackup(isBackedUp)
            })
            .disposed(by: disposeBag)
    }
    
    func handleDidBackup(_ didBackup: Bool) {
        didBackupCompletion?(didBackup)
        
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
    
    @objc func buttonBackupUsingICloudDidTouch() {
        guard let account = accountStorage.account?.phrase else {return}
        authenticationHandler.authenticate(
            presentationStyle: .init(
                isRequired: false,
                isFullScreen: false,
                completion: { [weak self] in
                    self?.accountStorage.saveICloud(phrases: account.joined(separator: " "))
                    self?.didBackupSubject.accept(true)
                }
            )
        )
    }
    
    @objc func buttonBackupManuallyDidTouch() {
        if didBackupSubject.value {
            authenticationHandler.authenticate(
                presentationStyle: .init(
                    isRequired: false,
                    isFullScreen: false,
                    completion: { [weak self] in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                            self?.showSeedPhrasesVC()
                        }
                    }
                )
            )
        } else {
            showBackupManuallyVC()
        }        
    }
    
    private func showBackupManuallyVC() {
        let vc = scenesFactory.makeBackupManuallyVC()
        vc.delegate = self
        let nc = BENavigationController(rootViewController: vc)
        
        let modalVC = WLIndicatorModalVC()
        modalVC.add(child: nc, to: modalVC.containerView)
        
        present(modalVC, animated: true, completion: nil)
    }
    
    private func showSeedPhrasesVC() {
        let vc = scenesFactory.makeBackupShowPhrasesVC()
        
        let nc = BENavigationController(rootViewController: vc)
        
        let modalVC = WLIndicatorModalVC()
        modalVC.add(child: nc, to: modalVC.containerView)
        
        present(modalVC, animated: true, completion: nil)
    }
}

extension BackupVC: BackupManuallyVCDelegate {
    func backupManuallyVCDidBackup(_ vc: BackupManuallyVC) {
        Defaults.didBackupOffline = true
        didBackupSubject.accept(true)
    }
}
