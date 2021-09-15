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
        lazy var receiveBTCView = BEView()
        
        // MARK: - Initializers
        init(viewModel: ReceiveTokenViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        func layout() {
            scrollView.contentInset.modify(dLeft: -.defaultPadding, dRight: -.defaultPadding)
            stackView.addArrangedSubviews {
                UIButton(label: "switch", textColor: .black)
                    .onTap(self, action: #selector(switchTokenType))
                receiveSolanaView
                receiveBTCView
            }
        }
        
        func bind() {
            viewModel.tokenTypeDriver
                .drive(onNext: {[weak self] token in
                    switch token {
                    case .solana:
                        self?.receiveSolanaView.isHidden = false
                        self?.receiveBTCView.isHidden = true
                    case .btc:
                        self?.receiveSolanaView.isHidden = true
                        self?.receiveBTCView.isHidden = false
                    }
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc func switchTokenType() {
            viewModel.switchToken(.allCases.randomElement()!)
        }
    }
}
