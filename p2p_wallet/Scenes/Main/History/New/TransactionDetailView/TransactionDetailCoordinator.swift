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
    case pendingTransaction(PendingTransaction)
}

class TransactionDetailCoordinator: SmartCoordinator<Void> {
    let input: TransactionDetailCoordiantorInput
    let style: DetailTransactionStyle

    init(input: TransactionDetailCoordiantorInput, style: DetailTransactionStyle = .active, presentingViewController: UIViewController) {
        self.input = input
        self.style = style
        super.init(presentation: SmartCoordinatorPresentPresentation(presentingViewController))
    }
    
    deinit {
        print("Deinit")
    }
    
    override func build() -> UIViewController {
        let vm: DetailTransactionViewModel

        switch input {
        case let .parsedTransaction(trx):
            vm = DetailTransactionViewModel(parsedTransaction: trx, style: style)
        case let .historyTransaction(trx):
            vm = DetailTransactionViewModel(historyTransaction: trx)
        case let .pendingTransaction(trx):
            vm = DetailTransactionViewModel(pendingTransaction: trx)
        }

        let vc = BottomSheetController(rootView: DetailTransactionView(viewModel: vm))
        
        vm.action.sink { [weak self] action in
            switch action {
            case .close:
                vc.dismiss(animated: true)
                self?.result.send(completion: .finished)
            case let .share(url):
                self?.presentation.presentingViewController.dismiss(animated: true) {
                    let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                }
                self?.result.send(completion: .finished)
            }

        }.store(in: &subscriptions)

        return vc
    }
}
