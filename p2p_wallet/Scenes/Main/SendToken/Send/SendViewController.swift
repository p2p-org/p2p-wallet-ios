//
//  SendViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2021.
//

import Foundation
import UIKit

//protocol SendScenesFactory {
//    func makeSendDetailViewController() -> SendDetailViewController
//}
//
//@objc protocol SendViewControllerDelegate {
//
//}

extension Send {
    class ViewController: BaseVC {
        
        // MARK: - Properties
        let viewModel: ViewModel
        
        // MARK: - Initializer
        init(viewModel: ViewModel)
        {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func loadView() {
            view = RootView(viewModel: viewModel)
        }
        
        override func setUp() {
            super.setUp()
            
        }
        
        override func bind() {
            super.bind()
            viewModel.output.navigationScene
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene) {
//            switch scene {
//            case .detail:
//                break
//            }
        }
    }
}
