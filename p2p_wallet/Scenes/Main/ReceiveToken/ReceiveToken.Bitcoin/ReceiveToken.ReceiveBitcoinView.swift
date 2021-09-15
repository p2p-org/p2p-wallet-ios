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
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ReceiveTokenBitcoinViewModelType
        
        // MARK: - Initializers
        init(viewModel: ReceiveTokenBitcoinViewModelType) {
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
            let stackView = UIStackView(
                axis: .vertical,
                spacing: 20,
                alignment: .fill,
                distribution: .fill
            ) {
            }
            
            // add stackView
            stackView.autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }
        
        func bind() {
            
        }
    }
}
