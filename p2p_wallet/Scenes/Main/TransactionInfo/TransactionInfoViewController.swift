//
//  TransactionInfoViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import Foundation
import UIKit
import RxCocoa

class TransactionInfoViewController: WLIndicatorModalVC, CustomPresentableViewController {
    
    // MARK: - Properties
    @Injected private var viewModel: TransactionInfoViewModel
    lazy var rootView = TransactionInfoRootView()
    var viewTranslation = CGPoint(x: 0, y: 0)
    var transitionManager: UIViewControllerTransitioningDelegate?
    
    // MARK: - Initializer
    init(transaction: SolanaSDK.ParsedTransaction)
    {
        super.init()
        viewModel.set(transaction: transaction)
        modalPresentationStyle = .custom
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        containerView.addSubview(rootView)
        rootView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {[weak self] in self?.navigate(to: $0)})
            .disposed(by: disposeBag)
        
        Driver.combineLatest(
            viewModel.showDetailTransaction
                .distinctUntilChanged()
                .asDriver(onErrorJustReturn: false),
            viewModel.transaction.asDriver()
        )
            .drive(onNext: {[weak self] _ in
                self?.updatePresentationLayout(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: TransactionInfoNavigatableScene) {
        switch scene {
        case .explorer:
            showWebsite(url: "https://explorer.solana.com/tx/\(viewModel.transaction.value.signature ?? "")")
        }
    }
    
    // MARK: - Transitions
    override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        super.calculateFittingHeightForPresentedView(targetWidth: targetWidth) +
            rootView.fittingHeight(targetWidth: targetWidth)
    }
    
    var dismissalHandlingScrollView: UIScrollView? {
        rootView.scrollView
    }
}
