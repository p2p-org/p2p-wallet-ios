//
// Created by Giang Long Tran on 13.12.21.
//

import Foundation

extension ReceiveToken {
    class Scene: BEScene {
        @BENavigationBinding private var viewModel: SceneModel!
        
        init(viewModel: SceneModel) {
            super.init()
            
            self.viewModel = viewModel
        }
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        override func build() -> UIView {
            BESafeArea {
                UIStackView(axis: .vertical, alignment: .fill) {
                    // Navbar
                    WLNavigationBar(forAutoLayout: ()).setup { view in
                        guard let navigationBar = view as? WLNavigationBar else { return }
                        navigationBar.backgroundColor = .clear
                        navigationBar.titleLabel.text = L10n.receive
                        navigationBar.backButton.onTap { [unowned self] in self.back() }
                    }
                    UIView.defaultSeparator()
                    
                    BEScrollView(contentInsets: .init(x: .defaultPadding, y: .defaultPadding), spacing: 16) {
                        // Receive type button
                        if viewModel.shouldShowChainsSwitcher {
                            WLLargeButton {
                                UIStackView(axis: .horizontal) {
                                    UIImageView(width: 22, height: 22, image: .walletEdit)
                                    UIStackView(axis: .vertical, alignment: .leading) {
                                        UILabel(text: L10n.showingMyAddressFor, textSize: 13, textColor: .secondaryLabel)
                                        UILabel(text: "Solana network", textSize: 17)
                                    }.padding(.init(x: 12, y: 0))
                                }.padding(.init(x: 15, y: 15))
                            }
                        }
                        // Children
                        ReceiveSolanaView(viewModel: viewModel.receiveSolanaViewModel)
                        
                        ReceiveBitcoinView(viewModel: viewModel.receiveBitcoinViewModel, receiveSolanaViewModel: viewModel.receiveSolanaViewModel).setup { view in
                            viewModel.tokenTypeDriver.map { token in token == .solana ? true : false }.drive(view.rx.isHidden).disposed(by: disposeBag)
                        }
                    }
                }
            }
        }
    }
}
