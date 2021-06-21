//
//  CreateSecurityKeysViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Foundation
import UIKit

class CreateSecurityKeysViewController: BaseVC {
    
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    // MARK: - Properties
    let viewModel: CreateSecurityKeysViewModel
    
    lazy var backButton = UIImageView(width: 36, height: 36, image: .backSquare)
        .onTap(self, action: #selector(back))
    
    // MARK: - Initializer
    init(viewModel: CreateSecurityKeysViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = CreateSecurityKeysRootView(viewModel: viewModel, backButton: backButton)
    }
    
    override func bind() {
        super.bind()
        viewModel.errorSubject
            .subscribe(onNext: {error in
                self.showAlert(title: L10n.error, message: error)
            })
            .disposed(by: disposeBag)
    }
}
