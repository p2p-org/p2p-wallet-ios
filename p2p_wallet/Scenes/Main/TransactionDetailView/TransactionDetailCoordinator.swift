//
//  TransactionDetailCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/02/2023.
//

import Foundation
import History
import TransactionParser

class TransactionDetailCoordinator: SmartCoordinator<DetailTransactionStatus> {
    let viewModel: DetailTransactionViewModel

    init(viewModel: DetailTransactionViewModel, presentingViewController: UIViewController) {
        self.viewModel = viewModel
        super.init(presentation: SmartCoordinatorPresentPresentation(presentingViewController))
    }

    override func build() -> UIViewController {
        let vc = BottomSheetController(rootView: DetailTransactionView(viewModel: viewModel))

        viewModel.action.sink { [weak self] action in
            guard let self = self else { return }

            switch action {
            case .close:
                vc.dismiss(animated: true)
                self.handleResult()
            case let .share(url):
                self.presentation.presentingViewController.dismiss(animated: true) {
                    let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                }
                self.handleResult()
            }

        }.store(in: &subscriptions)

        return vc
    }
    
    private func handleResult() {
        result.send(viewModel.rendableTransaction.status)
        result.send(completion: .finished)
    }
}
