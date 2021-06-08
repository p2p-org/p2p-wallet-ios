//
//  Root.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import UIKit


//@objc protocol RootViewControllerDelegate {
//
//}

extension Root {
    class ViewController: BaseVC {
        override var preferredStatusBarStyle: UIStatusBarStyle {
            isLightStatusBarStyle ? .lightContent: .darkContent
        }
        
        // MARK: - Properties
        private let viewModel: ViewModel
        private let scenesFactory: RootViewControllerScenesFactory
        
        private var isLightStatusBarStyle = false
        
        // MARK: - Subviews
        lazy var blurEffectView: UIVisualEffectView = {
            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            return blurEffectView
        }()
        
        // MARK: - Initializer
        init(
            viewModel: ViewModel,
            scenesFactory: RootViewControllerScenesFactory
        ) {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            viewModel.reload()
            view.addSubview(blurEffectView)
            blurEffectView.autoPinEdgesToSuperviewEdges()
        }
        
        override func bind() {
            super.bind()
            // navigation scene
            viewModel.output.navigationScene
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            // authentication status
            viewModel.output.currentAuthenticationStatus
                .drive(onNext: {[weak self] in self?.handleAuthenticationStatus($0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            
        }
        
        private func handleAuthenticationStatus(_ status: AuthenticationPresentationStyle?) {
            
        }
        
        // MARK: - Helpers
        private func transitionAndMoveBlurViewToFront(to vc: UIViewController) {
            transition(to: vc)
            view.bringSubviewToFront(blurEffectView)
        }
    }
}
