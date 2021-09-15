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
        
        // MARK: - Subviews
        lazy var loadingView = BESpinnerView(size: 30, endColor: .h5887ff)
        
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
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
            
            // set min height to 200
            autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)
            
            // loadingView
            addSubview(loadingView)
            loadingView.autoCenterInSuperview()
            loadingView.animate()
        }
        
        func bind() {
            
        }
    }
}
