//
//  SendTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/02/2021.
//

import Foundation
import UIKit
import SwiftUI

class SendTokenViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: SendTokenViewModel
    
    // MARK: - Subviews
    
    // MARK: - Initializer
    init(viewModel: SendTokenViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = SendTokenRootView(viewModel: viewModel)
    }
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {
                switch $0 {
                case .present(let vc):
                    self.present(vc, animated: true, completion: nil)
                case .show(let vc):
                    self.show(vc, sender: nil)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
}
