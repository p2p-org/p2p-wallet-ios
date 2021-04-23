//
//  TokenSettingsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import UIKit
import Action

@objc protocol TokenSettingsViewControllerDelegate: class {
    @objc optional func tokenSettingsViewControllerDidCloseToken(_ vc: TokenSettingsViewController)
}

class TokenSettingsViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: TokenSettingsViewModel
    let rootViewModel: RootViewModel
    weak var delegate: TokenSettingsViewControllerDelegate?
    
    // MARK: - Subviews
    lazy var navigationBar: WLNavigationBar = {
        let navigationBar = WLNavigationBar(backgroundColor: .textWhite)
        navigationBar.backButton
            .onTap(self, action: #selector(back))
        navigationBar.titleLabel.text = L10n.walletSettings
        return navigationBar
    }()
    
    // MARK: - Initializer
    init(viewModel: TokenSettingsViewModel, rootViewModel: RootViewModel)
    {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        containerView.backgroundColor = .f6f6f8
        
        containerView.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        let rootView = TokenSettingsRootView(viewModel: viewModel)
        containerView.addSubview(rootView)
        rootView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        rootView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 10)
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {[unowned self] in self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    func navigate(to scene: TokenSettingsNavigatableScene) {
        switch scene {
        case .alert(let title, let description):
            showAlert(title: title?.uppercaseFirst, message: description)
        case .closeConfirmation:
            guard let symbol = viewModel.wallet?.token.symbol else {return}
            let vc = TokenSettingsCloseAccountConfirmationVC(symbol: symbol)
            vc.completion = {
                vc.dismiss(animated: true) { [unowned self] in
                    self.rootViewModel.authenticationSubject.onNext(
                        .init(
                            isRequired: false,
                            isFullScreen: false,
                            useBiometry: false,
                            completion: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                                    self?.viewModel.showProcessingAndClose()
                                }
                            })
                    )
                }
            }
            self.present(vc, animated: true, completion: nil)
        case .processTransaction:
            let vc = ProcessTransactionViewController(viewModel: viewModel.processTransactionViewModel)
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
}

extension TokenSettingsViewController: ProcessTransactionViewControllerDelegate {
    func processTransactionViewControllerDidComplete(_ vc: ProcessTransactionViewController) {
        vc.dismiss(animated: true) { [weak self] in
            self?.dismiss(animated: true, completion: { [weak self] in
                guard let strongSelf = self else {return}
                strongSelf.delegate?.tokenSettingsViewControllerDidCloseToken?(strongSelf)
            })
        }
    }
}
