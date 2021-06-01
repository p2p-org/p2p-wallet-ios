//
//  SendRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2021.
//

import UIKit
import RxSwift
//import SwiftUI

extension Send {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ViewModel
        
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
//struct SendRootView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            UIViewPreview {
//                Send.RootView(viewModel: Send.ViewModel())
//            }
//            .previewDevice("iPhone SE (2nd generation)")
//        }
//    }
//}

