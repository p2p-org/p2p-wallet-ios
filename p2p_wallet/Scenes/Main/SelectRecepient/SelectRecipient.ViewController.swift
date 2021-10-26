//
//  SelectRecipient.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.10.2021.
//

import Foundation
import UIKit
import RxSwift

extension SelectRecipient {
    class ViewController: WLIndicatorModalVC {

        // MARK: - Dependencies
        private let viewModel: SelectRecipientViewModelType
        // MARK: - Properties
        
        // MARK: - Methods
        init(viewModel: SelectRecipientViewModelType) {
            self.viewModel = viewModel
        }

        override func setUp() {
            super.setUp()

            let rootView = RootView(viewModel: viewModel)
            containerView.addSubview(rootView)
            rootView.autoPinEdgesToSuperviewEdges()
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .close:
                dismiss(animated: true)
            default:
                break
            }
        }
    }
}
