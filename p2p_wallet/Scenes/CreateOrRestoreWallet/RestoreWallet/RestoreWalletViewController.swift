//
//  RestoreWalletViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

protocol RestoreWalletScenesFactory {
    func makeEnterPhrasesVC() -> EnterPhrasesVC
    func makeWelcomeBackVC(phrases: [String]) -> WelcomeBackVC
}

class RestoreWalletViewController: WLIntroVC {
    
    // MARK: - Properties
    let viewModel: RestoreWalletViewModel
    let scenesFactory: RestoreWalletScenesFactory
    
    // MARK: - Subviews
    lazy var iCloudRestoreButton = WLButton.stepButton(enabledColor: .white, textColor: .black, label: " " + L10n.restoreUsingICloud)
        .onTap(viewModel, action: #selector(RestoreWalletViewModel.restoreFromICloud))
    lazy var restoreManuallyButton = WLButton.stepButton(type: .sub, label: L10n.restoreManually)
        .onTap(viewModel, action: #selector(RestoreWalletViewModel.restoreManually))
    
    // MARK: - Initializer
    init(viewModel: RestoreWalletViewModel, scenesFactory: RestoreWalletScenesFactory)
    {
        self.scenesFactory = scenesFactory
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        backButton.isHidden = false
        descriptionLabel.isHidden = false
        titleLabel.text = L10n.p2PWalletRecovery
        descriptionLabel.text = L10n.recoverYourP2PWalletManuallyOrUsingCloudServices
        
        buttonsStackView.addArrangedSubviews([
            iCloudRestoreButton,
            restoreManuallyButton
        ])
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
        
        viewModel.errorMessage
            .filter {$0 != nil}
            .subscribe(onNext: {message in
                self.showAlert(title: L10n.error, message: message!)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: RestoreWalletNavigatableScene) {
        switch scene {
        case .enterPhrases:
            let vc = scenesFactory.makeEnterPhrasesVC()
            let titleImageView = UIImageView(width: 24, height: 24, image: .securityKey, tintColor: .white)

            presentCustomModal(vc: vc, title: L10n.securityKey.uppercaseFirst, titleImageView: titleImageView)
        case .welcomeBack(phrases: let phrases):
            let vc = scenesFactory.makeWelcomeBackVC(phrases: phrases)
            transition(to: vc)
        }
    }
}
