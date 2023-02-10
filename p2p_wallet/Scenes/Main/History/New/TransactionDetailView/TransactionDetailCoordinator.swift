//
//  TransactionDetailCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/02/2023.
//

import Foundation
import TransactionParser

enum TransactionDetailCoordiantorInput {
    case parsedTransaction(ParsedTransaction)
}

class TransactionDetailCoordinator: SmartCoordinator<Void> {
    let input: TransactionDetailCoordiantorInput
    let style: DetailTransactionStyle

    init(input: TransactionDetailCoordiantorInput, style: DetailTransactionStyle = .active, presentingViewController: UIViewController) {
        self.input = input
        self.style = style
        super.init(presentation: SmartCoordinatorPresentPresentation(presentingViewController))
    }

    override func build() -> UIViewController {
        let vm: DetailTransactionViewModel

        switch input {
        case let .parsedTransaction(trx):
            vm = DetailTransactionViewModel(parsedTransaction: trx, style: style)
        }

        let vc = BottomSheetController(rootView: DetailTransactionView(viewModel: vm))

        vm.close.sink { _ in
            vc.dismiss(animated: true)
        }.store(in: &subscriptions)

        return vc
    }
}
