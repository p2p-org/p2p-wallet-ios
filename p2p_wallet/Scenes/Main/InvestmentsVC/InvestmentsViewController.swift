//
//  InvestmentsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import Foundation
import UIKit

class InvestmentsViewController: BaseVC, TabBarNeededViewController {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .hidden }

    // MARK: - Properties

    let viewModel: InvestmentsViewModel

    // MARK: - Initializer

    init(viewModel: InvestmentsViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    // MARK: - Methods

    override func loadView() {
        view = InvestmentsRootView(viewModel: viewModel)
    }

    override func bind() {
        super.bind()
//        viewModel.navigationSubject
//            .subscribe(onNext: {self.navigate(to: $0)})
//            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

//    private func navigate(to scene: InvestmentsNavigatableScene) {
//        switch scene {
//
//        }
//    }
}
