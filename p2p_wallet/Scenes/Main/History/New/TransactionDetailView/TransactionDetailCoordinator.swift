//
//  TransactionDetailCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/02/2023.
//

import Foundation

class TransactionDetailCoordinator: SmartCoordinator<Void> {
    let transaction: any RendableDetailTransaction
    let style: DetailTransactionStyle
    
    init(transaction: any RendableDetailTransaction, style: DetailTransactionStyle = .active, presentingViewController: UIViewController) {
        self.transaction = transaction
        self.style = style
        super.init(presentation: SmartCoordinatorPresentPresentation(presentingViewController))
    }
    
    override func build() -> UIViewController {
        let vm = DetailTransactionViewModel(rendableTransaction: transaction, style: style)
        let vc = BottomSheetController(rootView: DetailTransactionView(viewModel: vm))
        
        vm.close.sink { _ in
            vc.dismiss(animated: true)
        }.store(in: &subscriptions)
        
        return vc
    }
}
