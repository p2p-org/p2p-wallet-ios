//
//  ReceiveTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import UIKit
import Action

protocol ReceiveTokenSceneFactory {
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool) -> ChooseWalletViewController
}

class ReceiveTokenViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: ReceiveTokenViewModel
    let scenesFactory: ReceiveTokenSceneFactory
    lazy var rootView = ReceiveTokenRootView(viewModel: viewModel)
    
    // MARK: - Initializer
    init(viewModel: ReceiveTokenViewModel, scenesFactory: ReceiveTokenSceneFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill, arrangedSubviews: [
                UIImageView(width: 24, height: 24, image: .walletReceive, tintColor: .white)
                    .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
                UILabel(text: L10n.receive, textSize: 17, weight: .semibold),
                UIImageView(width: 32, height: 32, image: .share, tintColor: .a3a5ba)
                    .onTap(viewModel, action: #selector(ReceiveTokenViewModel.share))
            ])
                .padding(.init(all: 20)),
            UIView.separator(height: 1, color: .separator),
            rootView
        ])
        
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {[weak self] in self?.navigate(to: $0)})
            .disposed(by: disposeBag)
        viewModel.repository
            .stateObservable()
            .subscribe(onNext: {[weak self] state in
                self?.removeErrorView()
                switch state {
                case .initializing, .loading:
                    self?.rootView.showLoading()
                case .error:
                    self?.rootView.hideLoading()
                    self?.showErrorView(
                        error: self?.viewModel.repository.getError(),
                        retryAction: CocoaAction { [weak self] in
                            self?.viewModel.repository.reload()
                            return .just(())
                        }
                    )
                default:
                    self?.rootView.hideLoading()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: ReceiveTokenNavigatableScene) {
        switch scene {
        case .chooseWallet:
            let vc = scenesFactory.makeChooseWalletViewController(customFilter: nil, showOtherWallets: true)
            vc.completion = { [weak self, weak vc] wallet in
                self?.viewModel.wallet.accept(wallet)
                vc?.back()
            }
            present(vc, animated: true, completion: nil)
        case .explorer(let url):
            showWebsite(url: url)
        case .share(let pubkey):
            let vc = UIActivityViewController(activityItems: [pubkey], applicationActivities: nil)
            present(vc, animated: true, completion: nil)
        }
    }
}
