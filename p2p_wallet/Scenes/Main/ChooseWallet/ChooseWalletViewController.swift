//
//  ChooseWalletViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation
import UIKit

class ChooseWalletViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: ChooseWalletViewModel
    private lazy var rootView = ChooseWalletRootView(viewModel: viewModel)
    var completion: ((Wallet) -> Void)?
    
    // MARK: - Initializer
    init(viewModel: ChooseWalletViewModel)
    {
        self.viewModel = viewModel
        super.init()
//        modalPresentationStyle = .custom
//        transitioningDelegate = self
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.selectToken, textSize: 17, weight: .semibold),
                UILabel(text: L10n.close, textSize: 17, textColor: .h5887ff)
                    .onTap(self, action: #selector(back))
            ])
                .padding(.init(all: 20)),
            UIView.defaultSeparator(),
            rootView
        ])
        
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        viewModel.selectedWallet
            .subscribe(onNext: {[weak self] wallet in
                self?.completion?(wallet)
            })
            .disposed(by: disposeBag)
    }
}

//extension ChooseWalletViewController: UIViewControllerTransitioningDelegate {
//    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
//        ExpandablePresentationController(presentedViewController: presented, presenting: presenting)
//    }
//}
