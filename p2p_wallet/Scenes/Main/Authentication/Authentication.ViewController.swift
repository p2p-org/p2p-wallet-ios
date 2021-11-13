//
//  Authentication.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import Foundation
import UIKit

extension Authentication {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        @Injected private var viewModel: AuthenticationViewModelType
        
        // MARK: - Properties
        override var title: String? {
            didSet {
                navigationBar.titleLabel.text = title
            }
        }
        
        var isIgnorable: Bool = false {
            didSet {
                navigationBar.backButton.isHidden = !isIgnorable
            }
        }
        
        var useBiometry: Bool = true {
            didSet {
                
            }
        }
        
        // MARK: - Callbacks
        var onSuccess: (() -> Void)?
        var onCancel: (() -> Void)?
        
        // MARK: - Subviews
        private let navigationBar = WLNavigationBar(forAutoLayout: ())
        private lazy var pincodeView = WLPinCodeView(
            correctPincode: viewModel.getCurrentPincode() == nil ? nil: UInt(viewModel.getCurrentPincode()!),
            maxAttemptsCount: 3
        )
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            // navigation bar
            if isIgnorable {
                navigationBar.backButton.onTap(self, action: #selector(cancel))
            }
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            // pincode view
            let wrappedView = UIView(forAutoLayout: ())
            wrappedView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            wrappedView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            
            wrappedView.addSubview(pincodeView)
            pincodeView.autoCenterInSuperview()
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
            case .resetPincodeWithASeedPhrase:
                break
            default:
                break
            }
        }
        
        // MARK: - Actions
        @objc private func cancel() {
            dismiss(animated: true) { [weak self] in
                self?.onCancel?()
            }
        }
    }
}
