//
//  SwapTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import Foundation
import UIKit
import SwiftUI

class SwapTokenViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: SwapTokenViewModel
    
    // MARK: - Initializer
    init(viewModel: SwapTokenViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = SwapTokenRootView(viewModel: viewModel)
    }
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {
                switch $0 {
                
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
}

//@available(iOS 13, *)
//struct SwapTokenViewController_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            UIViewControllerPreview {
//                SwapTokenViewController()
//            }
//            .previewDevice("iPhone SE (2nd generation)")
//        }
//    }
//}
