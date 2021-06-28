//
//  ResetPinCodeWithSeedPhrasesViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Foundation
import UIKit

protocol ResetPinCodeWithSeedPhrasesScenesFactory {
    func makeEnterPhrasesVC() -> ResetPinCodeWithSeedPhrasesEnterPhrasesVC
    func makeCreatePassCodeVC() -> CreatePassCodeVC
}

class ResetPinCodeWithSeedPhrasesViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: ResetPinCodeWithSeedPhrasesViewModel
    let scenesFactory: ResetPinCodeWithSeedPhrasesScenesFactory
    var childNavigationController: BENavigationController!
    var completion: (() -> Void)?
    
    // MARK: - ChildVC
    lazy var enterPhrasesVC: WLEnterPhrasesVC = {
        let vc = scenesFactory.makeEnterPhrasesVC()
        vc.dismissAfterCompletion = false
        return vc
    }()
    
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
            let vc = scenesFactory.makeCreatePassCodeVC()
            vc.disableDismissAfterCompletion = true
            vc.completion = {[weak self] completed in
                if completed {
                    guard let pincode = vc.passcode else {
                        return
                    }
                    self?.viewModel.savePincode(pincode)
                    self?.dismiss(animated: true, completion: { [weak self] in
                        self?.completion?()
                    })
                    return
                }
            }
            childNavigationController.pushViewController(vc, animated: true)
        }
    }
}
