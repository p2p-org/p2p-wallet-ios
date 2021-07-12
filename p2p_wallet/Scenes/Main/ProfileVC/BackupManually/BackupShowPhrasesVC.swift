//
//  BackupShowPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/06/2021.
//

import Foundation
import Action

class BackupShowPhrasesVC: WLIndicatorModalVC, CustomPresentableViewController {
    var transitionManager: UIViewControllerTransitioningDelegate?
    fileprivate let childVC: _BackupShowPhrasesVC
    
    init(accountStorage: KeychainAccountStorage, authenticationHandler: AuthenticationHandler)
    {
        childVC = _BackupShowPhrasesVC(accountStorage: accountStorage, authenticationHandler: authenticationHandler)
        super.init()
        modalPresentationStyle = .custom
    }
    
    override func setUp() {
        super.setUp()
        add(child: childVC, to: containerView)
        
        if SystemVersion.isIOS13() {
            childVC.view.layoutIfNeeded()
        }
    }
    
    override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        super.calculateFittingHeightForPresentedView(targetWidth: targetWidth) +
            childVC.calculateFittingHeightForPresentedView(targetWidth: targetWidth)
    }
}

private class _BackupShowPhrasesVC: BackupManuallyBaseVC {
    lazy var backupUsingIcloudButton = WLButton.stepButton(
        enabledColor: .blackButtonBackground,
        textColor: .white,
        label: " " + L10n.backupUsingICloud
    )
        .onTap(self, action: #selector(backupUsingICloudButtonDidTouch))
    
    let authenticationHandler: AuthenticationHandler
    init(accountStorage: KeychainAccountStorage, authenticationHandler: AuthenticationHandler)
    {
        self.authenticationHandler = authenticationHandler
        super.init(accountStorage: accountStorage)
    }
    
    override func setUp() {
        super.setUp()
        phrasesListView.setUp(description: L10n.SaveThatSeedPhraseAndKeepItInTheSafePlace.willBeUsedForRecoveryAndBackup)
        
        rootView.stackView.addArrangedSubviews {
            UIView(height: 31)
            backupUsingIcloudButton
        }
        
        backupUsingIcloudButton.isEnabled = !accountStorage.didBackupUsingIcloud
    }
    
    @objc func backupUsingICloudButtonDidTouch() {
        guard let account = accountStorage.account?.phrase else {return}
        authenticationHandler.authenticate(
            presentationStyle: .init(
                isRequired: false,
                isFullScreen: false,
                completion: { [weak self] in
                    self?.accountStorage.saveICloud(phrases: account.joined(separator: " "))
                    self?.backupUsingIcloudButton.isEnabled = false
                }
            )
        )
    }
    
    func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        headerView.fittingHeight(targetWidth: targetWidth) +
            20 +
            1 +
            rootView.fittingHeight(targetWidth: targetWidth - 20 * 2) +
            31 +
            20
    }
}
