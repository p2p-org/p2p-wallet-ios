//
//  TokenSettingsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import UIKit
import Action
import RxSwift

@objc protocol TokenSettingsViewControllerDelegate: AnyObject {
    @objc optional func tokenSettingsViewControllerDidCloseToken(_ vc: TokenSettingsViewController)
}

protocol TokenSettingsScenesFactory {
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
}

class TokenSettingsViewController: WLIndicatorModalVC {
    // MARK: - Dependencies
    @Injected private var authenticationHandler: AuthenticationHandler
    @Injected private var scenesFactory: TokenSettingsScenesFactory
    
    // MARK: - Properties
    let viewModel: TokenSettingsViewModel
    weak var delegate: TokenSettingsViewControllerDelegate?
    
    // MARK: - Subviews
    lazy var navigationBar: WLNavigationBar = {
        let navigationBar = WLNavigationBar(forAutoLayout: ())
        navigationBar.backButton
            .onTap(self, action: #selector(back))
        navigationBar.titleLabel.text = L10n.walletSettings
        return navigationBar
    }()
    
    // MARK: - Initializer
    init(viewModel: TokenSettingsViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        containerView.backgroundColor = .white.onDarkMode(.h2b2b2b)
        
        containerView.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        let separator = UIView.separator(height: 1, color: .clear.onDarkMode(.separator))
        containerView.addSubview(separator)
        separator.autoPinEdge(.top, to: .bottom, of: navigationBar)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        
        let rootView = TokenSettingsRootView(viewModel: viewModel)
        containerView.addSubview(rootView)
        rootView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        rootView.autoPinEdge(.top, to: .bottom, of: separator)
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
                    self.authenticationHandler.authenticate(
                        presentationStyle: .init(
                            isRequired: false,
                            isFullScreen: false,
                            completion: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                                    self?.viewModel.closeAccount()
                                }
                            }
                        )
                    )
                }
            }
            self.present(vc, animated: true, completion: nil)
        case .processTransaction(let request, let transactionType):
            let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
}

extension TokenSettingsViewController: ProcessTransactionViewControllerDelegate {
    func processTransactionViewControllerDidComplete(_ vc: UIViewController) {
        vc.dismiss(animated: true) { [weak self] in
            self?.dismiss(animated: true, completion: { [weak self] in
                guard let strongSelf = self else {return}
                strongSelf.delegate?.tokenSettingsViewControllerDidCloseToken?(strongSelf)
            })
        }
    }
}
