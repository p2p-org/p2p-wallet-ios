//
//  ReceiveToken.ReceiveBitcoinView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

extension ReceiveToken {
    class ReceiveBitcoinView: BEView {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: ReceiveTokenBitcoinViewModelType
        private let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        
        // MARK: - Subviews
        private lazy var btcTypeLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var receiveNormalBTCView = ReceiveSolanaView(viewModel: receiveSolanaViewModel)
        private lazy var receiveRenBTCView = ReceiveRenBTCView(viewModel: viewModel)
        
        // MARK: - Initializers
        init(
            viewModel: ReceiveTokenBitcoinViewModelType,
            receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        ) {
            self.viewModel = viewModel
            self.receiveSolanaViewModel = receiveSolanaViewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        private func layout() {
            let stackView = UIStackView(
                axis: .vertical,
                spacing: 20,
                alignment: .fill,
                distribution: .fill
            ) {
                receiveNormalBTCView
                receiveRenBTCView
            }
            
            // add stackView
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
            
            // set min height to 200
            autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)
        }
        
        private func bind() {
            viewModel.isReceivingRenBTCDriver
                .drive(receiveNormalBTCView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.isReceivingRenBTCDriver
                .map {!$0}
                .drive(receiveRenBTCView.rx.isHidden)
                .disposed(by: disposeBag)
        }
    }
}
