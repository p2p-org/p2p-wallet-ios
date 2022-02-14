//
//  WLCreatePincodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import Foundation
import BEPureLayout

class WLCreatePincodeVC: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    // MARK: - Properties
    private let createPincodeTitle: String?
    private let confirmPincodeTitle: String?
    
    // MARK: - Subviews
    private lazy var childNC = UINavigationController(rootViewController: createPincodeVC)
    private lazy var createPincodeVC = WLPincodeVC()
    
    // MARK: - Callback
    var onSuccess: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    // MARK: - Initializers
    init(createPincodeTitle: String?, confirmPincodeTitle: String?) {
        self.createPincodeTitle = createPincodeTitle
        self.confirmPincodeTitle = confirmPincodeTitle
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        // add childNC
        add(child: childNC, to: view)
        
        // create pincode
        createPincodeVC.title = createPincodeTitle
        createPincodeVC.onCreate = {[weak self] pincode in
            let confirmPincodeVC = WLPincodeVC(currentPincode: pincode)
            confirmPincodeVC.title = self?.confirmPincodeTitle
            confirmPincodeVC.onSuccess = {[weak self] pincode in
                self?.onSuccess?(pincode)
            }
            self?.childNC.pushViewController(confirmPincodeVC, animated: true)
        }
        createPincodeVC.onCancel = {[weak self] in
            self?.onCancel?()
        }
    }
}
