//
//  TransactionDetailCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/02/2023.
//

import Foundation

class TransactionDetailCoordinator: SmartCoordinator<Void> {
    init(presentingViewController: UIViewController) {
        super.init(presentation: SmartCoordinatorBottomSheetPresentation(presentingViewController, height: 632))
    }
    
    override func build() -> UIViewController {
        let vm = DetailTransactionViewModel(rendableTransaction: MockedRendableDetailTransaction.send())
        let view = DetailTransactionView(viewModel: vm)
        return UIHostingControllerWithoutNavigation(rootView: view)
    }
}
