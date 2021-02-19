//
//  OnboardingViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit
import SwiftUI

class OnboardingViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: OnboardingViewModel
    
    // MARK: - Initializer
    init(viewModel: OnboardingViewModel = OnboardingViewModel())
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        
    }
    
    override func bind() {
        super.bind()
//        viewModel.navigationSubject
//            .subscribe(onNext: {
////                switch $0 {
////                
////                }
//            })
//            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
}

//@available(iOS 13, *)
//struct OnboardingViewController_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            UIViewControllerPreview {
//                OnboardingViewController()
//            }
//            .previewDevice("iPhone SE (2nd generation)")
//        }
//    }
//}
