//
//  RootViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit
import SwiftUI

class RootViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: RootViewModel
    
    // MARK: - Initializer
    init(viewModel: RootViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        viewModel.reload()
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {
                self.removeAllChilds()
                switch $0 {
                
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
}

//@available(iOS 13, *)
//struct RootViewController_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            UIViewControllerPreview {
//                RootViewController()
//            }
//            .previewDevice("iPhone SE (2nd generation)")
//        }
//    }
//}
