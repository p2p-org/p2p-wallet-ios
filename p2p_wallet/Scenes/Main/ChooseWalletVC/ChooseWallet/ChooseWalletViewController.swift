//
//  ChooseWalletViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation
import UIKit

class ChooseWalletViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: ChooseWalletViewModel
    let sceneFactory: MyWalletsScenesFactory
    var completion: ((Wallet) -> Void)?
    let customFilter: ((Wallet) -> Bool)
    
    // MARK: - Initializer
    init(viewModel: ChooseWalletViewModel, sceneFactory: MyWalletsScenesFactory, customFilter: ((Wallet) -> Bool)? = nil)
    {
        self.viewModel = viewModel
        self.sceneFactory = sceneFactory
        self.customFilter = customFilter ?? {$0.symbol == "SOL" || $0.amount > 0}
        super.init()
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    // MARK: - Methods
    override func loadView() {
        let rootView = ChooseWalletCollectionView(viewModel: viewModel.walletsVM, customFilter: customFilter)
        rootView.itemDidSelect = {
            self.completion?($0)
        }
        view = rootView
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func bind() {
        super.bind()
    }
}

extension ChooseWalletViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        ExpandablePresentationController(presentedViewController: presented, presenting: presenting)
    }
}
