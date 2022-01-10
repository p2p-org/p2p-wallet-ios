//
// Created by Giang Long Tran on 13.12.21.
//

import Foundation
import Resolver

extension ReceiveToken {
    class ViewController: BEScene {
        private var viewModel: ReceiveSceneModel!
        
        init(viewModel: ReceiveSceneModel) {
            self.viewModel = viewModel
            super.init()
            
            self.viewModel.navigation.drive(onNext: { [weak self] in self?.navigate(to: $0) }).disposed(by: disposeBag)
        }
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                // Navbar
                NewWLNavigationBar(title: L10n.receive, separatorEnable: false)
                    .onBack { [unowned self] in self.back() }
                
                BEScrollView(contentInsets: .init(x: .defaultPadding, y: .defaultPadding), spacing: 16) {
                    // Network button
                    if viewModel.shouldShowChainsSwitcher {
                        WLCard {
                            UIStackView(axis: .horizontal) {
                                // Wallet Icon
                                UIImageView(width: 44, height: 44)
                                    .with(.image, drivenBy: viewModel.tokenTypeDriver.map({ type in type.icon }), disposedBy: disposeBag)
                                // Text
                                UIStackView(axis: .vertical, alignment: .leading) {
                                    UILabel(text: L10n.showingMyAddressFor, textSize: 13, textColor: .secondaryLabel)
                                    UILabel(text: L10n.network("Solana"), textSize: 17)
                                        .setup { view in
                                            guard let view = view as? UILabel else { return }
                                            viewModel.tokenTypeDriver
                                                .map { L10n.network($0.localizedName).onlyUppercaseFirst() }
                                                .drive(view.rx.text)
                                                .disposed(by: disposeBag)
                                        }
                                }.padding(.init(x: 12, y: 0))
                                // Next icon
                                UIView.defaultNextArrow()
                            }.padding(.init(x: 15, y: 15))
                        }.onTap { [unowned self] in
                            self.viewModel.showSelectionNetwork()
                        }
                    }
                    // Children
                    ReceiveSolanaView(viewModel: viewModel.receiveSolanaViewModel)
                        .setup { view in
                            viewModel.tokenTypeDriver.map { token in token != .solana }.drive(view.rx.isHidden).disposed(by: disposeBag)
                        }
                    ReceiveBitcoinView(viewModel: viewModel.receiveBitcoinViewModel, receiveSolanaViewModel: viewModel.receiveSolanaViewModel)
                        .setup { view in
                            viewModel.tokenTypeDriver.map { token in token != .btc }.drive(view.rx.isHidden).disposed(by: disposeBag)
                        }
                }
            }
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.tabBarController?.tabBar.isHidden = false
        }
        
        override func viewWillDisappear(_ animated: Bool) { // As soon as vc disappears
            super.viewWillDisappear(true)
            self.tabBarController?.tabBar.isHidden = true
        }
    }
}

extension ReceiveToken.ViewController {
    func navigate(to scene: ReceiveToken.NavigatableScene?) {
        switch scene {
        case .showInExplorer(let mintAddress):
            let url = "https://explorer.solana.com/address/\(mintAddress)"
            guard let vc = WebViewController.inReaderMode(url: url) else { return }
            present(vc, animated: true)
        case .showBTCExplorer(let address):
            let url = "https://btc.com/btc/address/\(address)"
            guard let vc = WebViewController.inReaderMode(url: url) else { return }
            present(vc, animated: true)
        case .showRenBTCReceivingStatus:
            let vm = RenBTCReceivingStatuses.ViewModel(receiveBitcoinViewModel: viewModel.receiveBitcoinViewModel)
            let vc = RenBTCReceivingStatuses.NewViewController(viewModel: vm)
            show(vc, sender: nil)
        case .share(let address, let qrCode):
            if let qrCode = qrCode {
                let vc = UIActivityViewController(activityItems: [qrCode], applicationActivities: nil)
                present(vc, animated: true)
            } else if let address = address {
                let vc = UIActivityViewController(activityItems: [address], applicationActivities: nil)
                present(vc, animated: true)
            }
        case .help:
            let vc = ReceiveToken.HelpViewController()
            present(vc, animated: true)
        case .networkSelection:
            let vc = ReceiveToken.NetworkSelectionScene(viewModel: viewModel)
            show(vc, sender: nil)
        default:
            return
        }
    }
}
