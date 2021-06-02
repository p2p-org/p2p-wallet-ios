//
//  ProcessTransaction.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import UIKit
import RxSwift
//import SwiftUI

extension ProcessTransaction {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ViewModel
        var transactionStatusDidChange: (() -> Void)?
        
        // MARK: - Subviews
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
        }
        
        // MARK: - Layout
        private func layout() {
            
        }
        
        private func bind() {
            
        }
    }
}


//@available(iOS 13, *)
//struct ProcessTransactionRootView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            UIViewPreview {
//                ProcessTransaction.RootView(viewModel: ProcessTransaction.ViewModel())
//            }
//            .previewDevice("iPhone SE (2nd generation)")
//        }
//    }
//}

