//
//  TransactionDetailCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/02/2023.
//

import Foundation

class TransactionDetailCoordinator: SmartCoordinator<Void> {
    let transaction: any RendableDetailTransaction
    
    init(transaction: any RendableDetailTransaction, presentingViewController: UIViewController) {
        self.transaction = transaction
        super.init(presentation: SmartCoordinatorBottomSheetPresentation(presentingViewController, height: 632))
    }
    
    override func build() -> UIViewController {
        let vm = DetailTransactionViewModel(rendableTransaction: transaction)
        let vc = UIHostingControllerWithoutNavigation(rootView: DetailTransactionView(viewModel: vm))
        
        vm.close.sink { _ in
            vc.dismiss(animated: true)
        }.store(in: &subscriptions)
        
        return vc
    }
}
