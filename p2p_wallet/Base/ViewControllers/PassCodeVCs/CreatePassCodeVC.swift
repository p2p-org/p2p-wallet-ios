//
//  CreatePassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2020.
//

import Foundation
import THPinViewController

class CreatePassCodeVC: PassCodeVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .hidden }
    
    var passcode: String?
    
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
        let vc = ConfirmPasscodeVC(currentPasscode: passcode!)
        vc.completion = completion
        show(vc, sender: nil)
    }
}

private class ConfirmPasscodeVC: CreatePassCodeVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .normal() }
    
    init(currentPasscode: String) {
        super.init()
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
        pin == passcode
    }
    
    override func pinViewControllerWillDismiss(afterPinEntryWasSuccessful pinViewController: THPinViewController) {
        AccountStorage.shared.save(passcode!)
        completion?(true)
    }
}
