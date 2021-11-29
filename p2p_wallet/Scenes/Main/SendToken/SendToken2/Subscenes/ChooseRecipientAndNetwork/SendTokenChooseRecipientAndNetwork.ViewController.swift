//
//  SendTokenChooseRecipientAndNetwork.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import UIKit
import RxSwift

extension SendTokenChooseRecipientAndNetwork {
    class ViewController: SendToken2.BaseViewController {
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseRecipientAndNetworkViewModelType
        
        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var pagesVC = WLSegmentedPagesVC(items: [
            .init(label: L10n.address, viewController: addressVC),
            .init(label: L10n.contact, viewController: contactVC)
        ])
        
        private lazy var addressVC: AddressViewController = {
            let vc = AddressViewController(viewModel: viewModel)
            return vc
        }()
        
        private lazy var contactVC: ContactViewController = {
            let vc = ContactViewController(viewModel: viewModel)
            return vc
        }()
        
        // MARK: - Initializer
        init(viewModel: SendTokenChooseRecipientAndNetworkViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            let containerView = UIView(forAutoLayout: ())
            view.addSubview(containerView)
            containerView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            containerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            
            add(child: pagesVC, to: containerView)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {
                return
            }

            switch scene {
            }
        }
    }
}
