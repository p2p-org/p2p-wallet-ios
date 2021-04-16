//
//  ResetPinCodeWithSeedPhrasesViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Foundation
import UIKit

protocol ResetPinCodeWithSeedPhrasesScenesFactory {
    func makeEnterPhrasesVC() -> WLEnterPhrasesVC
    func makeCreatePassCodeVC() -> CreatePassCodeVC
}

class ResetPinCodeWithSeedPhrasesViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: ResetPinCodeWithSeedPhrasesViewModel
    let scenesFactory: ResetPinCodeWithSeedPhrasesScenesFactory
    var childNavigationController: BENavigationController!
    
    // MARK: - ChildVC
    lazy var enterPhrasesVC = scenesFactory.makeEnterPhrasesVC()
    
    // MARK: - Initializer
    init(
        viewModel: ResetPinCodeWithSeedPhrasesViewModel,
        scenesFactory: ResetPinCodeWithSeedPhrasesScenesFactory
    ) {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        childNavigationController = BENavigationController()
        add(child: childNavigationController, to: containerView)
        
        viewModel.navigationSubject.onNext(.enterSeedPhrases)
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
        
        viewModel.error
            .bind(to: enterPhrasesVC.error)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: ResetPinCodeWithSeedPhrasesNavigatableScene) {
        switch scene {
        case .enterSeedPhrases:
            childNavigationController.pushViewController(enterPhrasesVC, animated: true)
        case .createNewPasscode:
            childNavigationController.pushViewController(scenesFactory.makeCreatePassCodeVC(), animated: true)
        }
    }
}
