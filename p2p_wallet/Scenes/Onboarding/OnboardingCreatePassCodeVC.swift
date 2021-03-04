//
//  OnboardingCreatePassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/03/2021.
//

import Foundation

class OnboardingCreatePassCodeVC: CreatePassCodeVC {
    let viewModel: OnboardingViewModel
    
    lazy var backButton = UIImageView(width: 36, height: 36, image: .backButtonLight)
        .onTap(viewModel, action: #selector(OnboardingViewModel.cancelOnboarding))
    
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backButton)
        backButton.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
        backButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
    }
}
