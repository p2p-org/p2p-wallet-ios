//
//  TransactionDetailCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/02/2023.
//

import Foundation
import History
import TransactionParser

enum TransactionDetailCoordiantorInput {
    case parsedTransaction(ParsedTransaction)
    case historyTransaction(HistoryTransaction)
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
        case let .historyTransaction(trx):
            vm = DetailTransactionViewModel(historyTransaction: trx)
        }

        let vc = BottomSheetController(rootView: DetailTransactionView(viewModel: vm))

        vm.action.sink { [weak self] action in
            switch action {
            case .close:
                vc.dismiss(animated: true)
            case let .share(url):
                self?.presentation.presentingViewController.dismiss(animated: true) {
                    let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                }
            }

        }.store(in: &subscriptions)

        return vc
    }
}
