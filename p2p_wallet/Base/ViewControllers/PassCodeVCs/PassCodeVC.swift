//
//  PassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2020.
//

import Foundation
import THPinViewController

class PassCodeVC: BEViewController, THPinViewControllerDelegate {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .hidden }
    
    var completion: ((Bool) -> Void)?
    var cancelledCompletion: (() -> Void)?
    var embededPinVC: THPinViewController!
    
    var backgroundColor: UIColor? {
        get {embededPinVC.backgroundColor}
        set {embededPinVC.backgroundColor = newValue}
    }
    
    var promptColor: UIColor? {
        get {embededPinVC.promptColor}
        set {embededPinVC.promptColor = newValue}
    }
    
    var tintColor: UIColor? {
        get {embededPinVC.view.tintColor}
        set {embededPinVC.view.tintColor = newValue}
    }
    
    var promptTitle: String? {
        get {embededPinVC.promptTitle}
        set {embededPinVC.promptTitle = newValue}
    }
    
    var leftBottomButton: UIButton? {
        get {embededPinVC.leftBottomButton}
        set {embededPinVC.leftBottomButton = newValue}
    }
    
    var disableDismissAfterCompletion: Bool {
        get {
            embededPinVC.disableDismissAfterCompletion
        }
        set {
            embededPinVC.disableDismissAfterCompletion = newValue
        }
    }
    
    override init() {
        super.init()
        embededPinVC = THPinViewController(delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup views
        backgroundColor = .background
        promptColor = .textBlack
        tintColor = .grayPanel // pinViewButtonBgColor
        embededPinVC.bottomButtonImage = .delete
        
        embededPinVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(embededPinVC)
        view.addSubview(embededPinVC.view)
        embededPinVC.view.autoPinEdgesToSuperviewEdges()
        embededPinVC.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        embededPinVC.clear()
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
    
    func pinViewControllerWillDismiss(afterPinEntryWasCancelled pinViewController: THPinViewController) {
        cancelledCompletion?()
    }
    
    // MARK: - Orientation
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
}
