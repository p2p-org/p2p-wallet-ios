//
//  ReceiveToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import UIKit

extension ReceiveToken {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Properties
        let viewModel: ReceiveTokenViewModelType
        
        // MARK: - Views
        lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backgroundColor = .clear
            navigationBar.titleLabel.text = L10n.receive
            return navigationBar
        }()
        
        lazy var headerView = UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill) {
            UIImageView(width: 24, height: 24, image: .walletReceive, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12)
            UILabel(text: L10n.receive, textSize: 17, weight: .semibold)
        }
            .padding(.init(all: 20))
        lazy var rootView = RootView(viewModel: viewModel)
        
        // MARK: - Initializer
        init(viewModel: ReceiveTokenViewModelType) {
            self.viewModel = viewModel
            super.init()
            modalPresentationStyle = .custom
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                navigationBar
                UIView.defaultSeparator()
                rootView
            }
            
            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewSafeArea()
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            navigationBar.backButton.onTap(self, action: #selector(back))
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
                let vc = SelectBTCTypeViewController(viewModel: viewModel.receiveBitcoinViewModel, selectedOption: selectedOption)
                present(vc, interactiveDismissalType: .standard)
            case .showRenBTCReceivingStatus:
                let vm = RenBTCReceivingStatuses.ViewModel(receiveBitcoinViewModel: viewModel.receiveBitcoinViewModel)
                let vc = RenBTCReceivingStatuses.ViewController(viewModel: vm)
                let nc = FlexibleHeightNavigationController(rootViewController: vc)
                present(nc, interactiveDismissalType: .standard)
            case .share(let address, let qrCode):
                if let qrCode = qrCode {
                    let vc = UIActivityViewController(activityItems: [qrCode], applicationActivities: nil)
                    present(vc, animated: true, completion: nil)
                } else if let address = address{
                    let vc = UIActivityViewController(activityItems: [address], applicationActivities: nil)
                    present(vc, animated: true, completion: nil)
                }
            case .help:
                let vc = HelpViewController()
                present(vc, animated: true, completion: nil)
            case .none:
                break
            }
        }
    }
}
