//
//  ReceiveToken.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift

extension ReceiveToken {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ReceiveTokenViewModelType
        
        // MARK: - Subviews
        lazy var receiveSolanaView = ReceiveSolanaView(viewModel: viewModel.receiveSolanaViewModel)
        
        // MARK: - Initializers
        init(viewModel: ReceiveTokenViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
//            layout()
//            bind()
        }
    }
}
