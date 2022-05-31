//
//  TokenSettingsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Action
import Foundation
import Resolver
import RxSwift
import UIKit

@objc protocol TokenSettingsViewControllerDelegate: AnyObject {
    @objc optional func tokenSettingsViewControllerDidCloseToken(_ vc: TokenSettingsViewController)
}

class TokenSettingsViewController: WLIndicatorModalVC {
    // MARK: - Properties

    private let viewModel: TokenSettingsViewModel
    @Injected private var authenticationHandler: AuthenticationHandlerType
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
            .subscribe(onNext: { [unowned self] in self.navigate(to: $0) })
            .disposed(by: disposeBag)
    }

    func navigate(to scene: TokenSettingsNavigatableScene) {
        switch scene {
        case let .alert(title, description):
            showAlert(title: title?.uppercaseFirst, message: description)
        case .closeConfirmation:
            guard let symbol = viewModel.wallet?.token.symbol else { return }
            let vc = TokenSettingsCloseAccountConfirmationVC(symbol: symbol)
            vc.completion = { [weak vc] in
                vc?.dismiss(animated: true) { [weak self] in
                    self?.authenticationHandler.authenticate(
                        presentationStyle: .init(
                            completion: { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                                    self?.viewModel.closeAccount()
                                }
                            }
                        )
                    )
                }
            }
            present(vc, animated: true, completion: nil)
        case let .processTransaction(transaction):
            let vm = ProcessTransaction.ViewModel(processingTransaction: transaction)
            let vc = ProcessTransaction.Status.ViewController(viewModel: vm)
            vc.dismissCompletion = { [weak self] in
                self?.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.tokenSettingsViewControllerDidCloseToken?(self)
                })
            }
//            vc.delegate = self
            present(vc, interactiveDismissalType: .none, completion: nil)
        }
    }
}
