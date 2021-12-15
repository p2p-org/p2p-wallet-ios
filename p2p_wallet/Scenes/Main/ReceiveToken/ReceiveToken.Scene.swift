//
// Created by Giang Long Tran on 13.12.21.
//

import Foundation

extension ReceiveToken {
    class Scene: BEScene {
        @BENavigationBinding private var viewModel: ReceiveSceneModel!
        
        init(viewModel: ReceiveSceneModel) {
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
                        // Network button
                        if viewModel.shouldShowChainsSwitcher {
                            WLLargeButton {
                                UIStackView(axis: .horizontal) {
                                    // Wallet Icon
                                    UIImageView(width: 44, height: 44)
                                        .with(.image, drivenBy: viewModel.tokenTypeDriver.map({ type in type.icon }), disposedBy: disposeBag)
                                    // Text
                                    UIStackView(axis: .vertical, alignment: .leading) {
                                        UILabel(text: L10n.showingMyAddressFor, textSize: 13, textColor: .secondaryLabel)
                                        UILabel(text: L10n.network("Solana"), textSize: 17)
                                    }.padding(.init(x: 12, y: 0))
                                    // Next icon
                                    UIView.defaultNextArrow()
                                }.padding(.init(x: 15, y: 15))
                            }.onTap {
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
        }
    }
}
