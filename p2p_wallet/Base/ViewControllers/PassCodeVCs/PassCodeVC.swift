//
//  PassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2020.
//

import Foundation
import THPinViewController

class PassCodeVC: THPinViewController, THPinViewControllerDelegate {
    var canIgnore = false
    var completion: ((Bool) -> Void)?
    
    init() {
        super.init(delegate: nil)
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup views
        backgroundColor = .pinViewBgColor
        promptColor = .textBlack
        view.tintColor = .pinViewButtonBgColor
        
        // Add cancel button on bottom
        if !canIgnore {
            navigationController?.setNavigationBarHidden(true, animated: false)
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.close, style: .plain, target: self, action: #selector(cancelButtonDidTouch))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Actions
    @objc func cancelButtonDidTouch() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Delegate
    func pinLength(for pinViewController: THPinViewController) -> UInt {
        return 6
    }
    
    func pinViewController(_ pinViewController: THPinViewController, isPinValid pin: String) -> Bool {
        fatalError("must override")
    }
    
    func userCanRetry(in pinViewController: THPinViewController) -> Bool {
        true
    }
    
    func pinViewControllerWillDismiss(afterPinEntryWasSuccessful pinViewController: THPinViewController) {
        completion?(true)
    }
    
    func pinViewControllerWillDismiss(afterPinEntryWasUnsuccessful pinViewController: THPinViewController) {
        completion?(false)
    }
    
    // MARK: - Orientation
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
}
