//
//  ReceiveToken.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift

extension ReceiveToken {
    class RootView: BECompositionView {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        private let allTokenTypes = TokenType.allCases
        
        // MARK: - Properties
        private let viewModel: ReceiveTokenViewModelType
        
        init(viewModel: ReceiveTokenViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        override func build() -> UIView {
            BEScrollView(contentInsets: .init(x: .defaultPadding, y: .defaultPadding), spacing: 16) {
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
                ReceiveSolanaView(viewModel: viewModel.receiveSolanaViewModel).setup { view in
                    viewModel.tokenTypeDriver.map { token in token == .solana ? false : true }.drive(view.rx.isHidden).disposed(by: disposeBag)
                }
                ReceiveBitcoinView(viewModel: viewModel.receiveBitcoinViewModel, receiveSolanaViewModel: viewModel.receiveSolanaViewModel).setup { view in
                    viewModel.tokenTypeDriver.map { token in token == .solana ? true : false }.drive(view.rx.isHidden).disposed(by: disposeBag)
                }
            }
        }
    }
}