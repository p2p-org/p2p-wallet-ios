//
//  CreatePassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2020.
//

import Foundation
import THPinViewController

class BaseCreatePassCodeVC: PassCodeVC {
    lazy var backButton = UIImageView(width: 36, height: 36, image: .backSquare)
        .onTap(self, action: #selector(back))
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .hidden }
    var passcode: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backButton)
        backButton.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
        backButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
    }
}

class CreatePassCodeVC: BaseCreatePassCodeVC {
    fileprivate var confirmPasscodeVC: ConfirmPasscodeVC?
    
    override var disableDismissAfterCompletion: Bool {
        didSet {
            confirmPasscodeVC?.disableDismissAfterCompletion = disableDismissAfterCompletion
        }
    }
    
    init(promptTitle: String = L10n.createAPINCodeToProtectYourWallet) {
        super.init()
        self.promptTitle = promptTitle
    }
    
    override func pinViewController(_ pinViewController: THPinViewController, isPinValid pin: String) -> Bool {
        self.passcode = pin
        return true
    }
    
    override func pinViewControllerWillDismiss(afterPinEntryWasSuccessful pinViewController: THPinViewController) {
        showConfirmPassCodeVC()
    }
    
    func showConfirmPassCodeVC() {
        // show confirm
        confirmPasscodeVC = ConfirmPasscodeVC(currentPasscode: passcode!)
        confirmPasscodeVC!.completion = completion
        confirmPasscodeVC?.disableDismissAfterCompletion = disableDismissAfterCompletion
        show(confirmPasscodeVC!, sender: nil)
    }
}

private class ConfirmPasscodeVC: BaseCreatePassCodeVC {
    init(currentPasscode: String, promptTitle: String = L10n.confirmPINCode.uppercaseFirst) {
        super.init()
        self.passcode = currentPasscode
        self.promptTitle = promptTitle
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
