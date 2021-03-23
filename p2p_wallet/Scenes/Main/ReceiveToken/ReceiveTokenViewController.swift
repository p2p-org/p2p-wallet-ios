//
//  ReceiveTokenViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import UIKit

class ReceiveTokenViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: ReceiveTokenViewModel
    lazy var rootView = ReceiveTokenRootView(viewModel: viewModel)
    
    // MARK: - Initializer
    init(viewModel: ReceiveTokenViewModel)
    {
        self.viewModel = viewModel
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
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: ReceiveTokenNavigatableScene) {
        switch scene {
        
        }
    }
}
