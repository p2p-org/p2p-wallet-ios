//
//  TokenSettingsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import UIKit

class TokenSettingsViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: TokenSettingsViewModel
    
    // MARK: - Initializer
    init(viewModel: TokenSettingsViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = TokenSettingsRootView(viewModel: viewModel)
    }
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func bind() {
        super.bind()
    }
}
