//
//  ReceiveToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import UIKit

extension ReceiveToken {
    class ViewController: WLIndicatorModalVC, CustomPresentableViewController {
        // MARK: - Properties
        let viewModel: ReceiveTokenViewModelType
        lazy var headerView = UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill) {
            UIImageView(width: 24, height: 24, image: .walletReceive, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12)
            UILabel(text: L10n.receive, textSize: 17, weight: .semibold)
        }
            .padding(.init(all: 20))
        lazy var rootView = RootView(viewModel: viewModel)
        var transitionManager: UIViewControllerTransitioningDelegate?
        
        // MARK: - Initializer
        init(viewModel: ReceiveTokenViewModelType)
        {
            self.viewModel = viewModel
            super.init()
            modalPresentationStyle = .custom
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                headerView
                UIView.defaultSeparator()
                rootView
            }
            
            containerView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.updateLayoutDriver
                .drive(onNext: {[weak self] _ in self?.updatePresentationLayout(animated: true)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .showInExplorer(let mintAddress):
                let url = "https://explorer.solana.com/address/\(mintAddress)"
                showWebsite(url: url)
            case .showBTCExplorer(let address):
                let url = "https://btc.com/btc/address/\(address)"
                showWebsite(url: url)
            case .chooseBTCOption(let selectedOption):
                let vc = SelectBTCTypeViewController(selectedOption: selectedOption)
                present(vc, interactiveDismissalType: .standard)
            case .share(let address):
                let vc = UIActivityViewController(activityItems: [address], applicationActivities: nil)
                present(vc, animated: true, completion: nil)
            case .help:
                let vc = HelpViewController()
                present(vc, animated: true, completion: nil)
            default:
                break
            }
        }
        
        // MARK: - Transition
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            super.calculateFittingHeightForPresentedView(targetWidth: targetWidth)
                + headerView.fittingHeight(targetWidth: targetWidth)
                + 1 // separator
                + rootView.fittingHeight(targetWidth: targetWidth)
        }
        
        var dismissalHandlingScrollView: UIScrollView? {
            rootView.scrollView
        }
    }
}
