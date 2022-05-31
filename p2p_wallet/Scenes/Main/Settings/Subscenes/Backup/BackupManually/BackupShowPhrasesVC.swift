//
//  BackupShowPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/06/2021.
//

import Action
import Foundation
import Resolver

class BackupShowPhrasesVC: WLIndicatorModalVC, CustomPresentableViewController {
    var transitionManager: UIViewControllerTransitioningDelegate?
    fileprivate let childVC: _BackupShowPhrasesVC

    override init() {
        childVC = _BackupShowPhrasesVC()
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

    @Injected private var authenticationHandler: AuthenticationHandlerType

    override func setUp() {
        super.setUp()
        phrasesListView
            .setUp(description: L10n.SaveThatSeedPhraseAndKeepItInTheSafePlace.willBeUsedForRecoveryAndBackup)

        rootView.stackView.addArrangedSubviews {
            UIView(height: 31)
            backupUsingIcloudButton
        }

        backupUsingIcloudButton.isHidden = true
        if Defaults.didBackupOffline, !storage.didBackupUsingIcloud {
            backupUsingIcloudButton.isHidden = false
        }
    }

    @objc func backupUsingICloudButtonDidTouch() {
        guard let account = storage.account?.phrase else { return }
        authenticationHandler.authenticate(
            presentationStyle: .init(
                completion: { [weak self] _ in
                    _ = self?.storage.saveToICloud(
                        account: .init(
                            name: self?.storage.getName(),
                            phrase: account.joined(separator: " "),
                            derivablePath: self?.storage.getDerivablePath() ?? .default
                        )
                    )
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
