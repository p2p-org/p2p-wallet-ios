//
//  CreatePassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2020.
//

import Foundation
import THPinViewController

class CreatePassCodeVC: PassCodeVC {
    var passcode: String?
    let accountStorage: KeychainAccountStorage
    
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
        super.init()
        embededPinVC.disableDismissAfterCompletion = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        promptTitle = L10n.createAPINCodeToProtectYourWallet
    }
    
    override func pinViewController(_ pinViewController: THPinViewController, isPinValid pin: String) -> Bool {
        self.passcode = pin
        return true
    }
    
    override func pinViewControllerWillDismiss(afterPinEntryWasSuccessful pinViewController: THPinViewController) {
        // show confirm
        let vc = ConfirmPasscodeVC(currentPasscode: passcode!, accountStorage: accountStorage)
        vc.completion = completion
        show(vc, sender: nil)
    }
}

private class ConfirmPasscodeVC: CreatePassCodeVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .normal(translucent: true) }
    
    init(currentPasscode: String, accountStorage: KeychainAccountStorage) {
        super.init(accountStorage: accountStorage)
        self.passcode = currentPasscode
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        promptTitle = L10n.confirmPINCode.uppercaseFirst
    }
    
    override func pinViewController(_ pinViewController: THPinViewController, isPinValid pin: String) -> Bool {
        if pin != passcode {
            embededPinVC.errorTitle = L10n.pinCodesDoNotMatch
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.embededPinVC.errorTitle = nil
            }
        }
        return pin == passcode
    }
    
    override func pinViewControllerWillDismiss(afterPinEntryWasSuccessful pinViewController: THPinViewController) {
        accountStorage.save(passcode!)
        completion?(true)
    }
}
