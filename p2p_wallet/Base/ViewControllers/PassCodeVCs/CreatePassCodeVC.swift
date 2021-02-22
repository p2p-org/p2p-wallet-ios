//
//  CreatePassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2020.
//

import Foundation
import THPinViewController

class BaseCreatePassCodeVC: PassCodeVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .hidden }
    var passcode: String?
    
    var disableDismissAfterCompletion: Bool {
        get {
            embededPinVC.disableDismissAfterCompletion
        }
        set {
            embededPinVC.disableDismissAfterCompletion = newValue
        }
    }
}

class CreatePassCodeVC: BaseCreatePassCodeVC {
    fileprivate var confirmPasscodeVC: ConfirmPasscodeVC?
    
    override var disableDismissAfterCompletion: Bool {
        didSet {
            confirmPasscodeVC?.disableDismissAfterCompletion = disableDismissAfterCompletion
        }
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
        confirmPasscodeVC = ConfirmPasscodeVC(currentPasscode: passcode!)
        confirmPasscodeVC!.completion = completion
        confirmPasscodeVC?.disableDismissAfterCompletion = disableDismissAfterCompletion
        show(confirmPasscodeVC!, sender: nil)
    }
}

private class ConfirmPasscodeVC: BaseCreatePassCodeVC {
    lazy var backButton = UIImageView(width: 36, height: 36, image: .backButtonLight)
        .onTap(self, action: #selector(back))
    
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
        view.addSubview(backButton)
        backButton.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
        backButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
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
        completion?(true)
    }
}
