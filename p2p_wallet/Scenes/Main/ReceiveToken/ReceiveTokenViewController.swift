//
//  ReceiveTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import UIKit

protocol ReceiveTokenSceneFactory {
    func makeChooseWalletVC(customFilter: ((Wallet) -> Bool)?) -> ChooseWalletVC
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
            .stateObservable
            .subscribe(onNext: {[weak self] state in
                self?.rootView.removeErrorView()
                switch state {
                case .initializing, .loading:
                    self?.rootView.showLoading()
                case .error(let error):
                    self?.rootView.hideLoading()
                    self?.rootView.showErrorView(error: error)
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
            let vc = scenesFactory.makeChooseWalletVC(customFilter: nil)
            vc.completion = {wallet in
                let wallet = self.viewModel.repository.wallets.first(where: {$0.pubkey == wallet.pubkey})
                self.viewModel.wallet.accept(wallet)
                vc.back()
            }
            presentCustomModal(vc: vc, title: L10n.selectWallet)
        case .explorer(let url):
            showWebsite(url: url)
        }
    }
}
