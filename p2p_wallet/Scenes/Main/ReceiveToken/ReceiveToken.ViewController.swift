//
//  ReceiveToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import UIKit

extension ReceiveToken {
    class ViewController: WLIndicatorModalVC {
        
        // MARK: - Properties
        let viewModel: ViewModel
        lazy var rootView = RootView(viewModel: viewModel)
        
        // MARK: - Initializer
        init(viewModel: ViewModel)
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
                    UILabel(text: L10n.receive + " " + viewModel.output.tokenWallet?.token.symbol, textSize: 17, weight: .semibold),
                    UIImageView(width: 32, height: 32, image: .questionMarkCircle, tintColor: .iconSecondary)
                        .onTap(viewModel, action: #selector(ReceiveToken.ViewModel.showHelp))
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
            viewModel.output.navigationScene
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .showInExplorer(let mintAddress):
                let url = "https://explorer.solana.com/address/\(mintAddress)"
                showWebsite(url: url)
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
    }
}
