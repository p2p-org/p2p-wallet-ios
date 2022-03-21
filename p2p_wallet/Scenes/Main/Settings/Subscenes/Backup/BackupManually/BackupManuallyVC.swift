//
//  BackupManuallyVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/12/2020.
//

import Action
import Foundation

protocol BackupManuallyVCDelegate: AnyObject {
    func backupManuallyVCDidBackup(_ vc: BackupManuallyVC)
}

class BackupManuallyVC: BackupManuallyBaseVC {
    weak var delegate: BackupManuallyVCDelegate?

    lazy var continueButton = WLButton.stepButton(type: .blue, label: L10n.continue)
        .onTap(self, action: #selector(continueButtonDidTouch))

    override func setUp() {
        super.setUp()

        rootView.stackView.addArrangedSubviews {
            UIView(height: 31)
            continueButton
        }
    }

    // MARK: - Actions

    @objc func continueButtonDidTouch() {
        let vc = BackupPasteSeedPhrasesVC()
        vc.completion = { [weak self] phrases in
            if phrases == self?.phrases {
                self?.dismiss(animated: true) { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.backupManuallyVCDidBackup(self)
                }
            } else {
                self?.showErrorView(title: L10n.error, description: L10n.thePhrasesYouHasEnteredIsNotCorrect)
            }
        }
        show(vc, sender: nil)
    }
}
