//
//  ReceiveToken.ReceiveBitcoinView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension ReceiveToken {
    class ReceiveBitcoinView: BEView {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: ReceiveTokenBitcoinViewModelType
        private let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        
        // MARK: - Subviews
        private lazy var receiveRenBTCSwitcher = UISwitch()
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
                ReceiveToken.switchField(text: L10n.iWantToReceiveRenBTC, switch: receiveRenBTCSwitcher)
                    .padding(.init(x: 20, y: 0))
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
            receiveRenBTCSwitcher
                .addTarget(self, action: #selector(receiveRenBTCSwitcherDidTouch(sender:)), for: .valueChanged)
            
            viewModel.isReceivingRenBTCDriver
                .drive(receiveRenBTCSwitcher.rx.isOn)
                .disposed(by: disposeBag)
            
            viewModel.isReceivingRenBTCDriver
                .drive(receiveNormalBTCView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.isReceivingRenBTCDriver
                .map {!$0}
                .drive(receiveRenBTCView.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        @objc private func receiveRenBTCSwitcherDidTouch(sender: UISwitch) {
            viewModel.toggleIsReceivingRenBTC(isReceivingRenBTC: sender.isOn)
        }
    }
}
