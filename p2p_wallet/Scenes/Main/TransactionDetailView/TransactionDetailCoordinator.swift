//
//  TransactionDetailCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/02/2023.
//

import Foundation
import History
import SafariServices
import TransactionParser

class TransactionDetailCoordinator: SmartCoordinator<Void> {
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
                self.result.send(completion: .finished)
            case let .share(url):
                self.presentation.presentingViewController.dismiss(animated: true) {
                    let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    UIApplication
                        .shared
                        .windows
                        .first?
                        .rootViewController?
                        .present(av, animated: true, completion: nil)
                }
                self.result.send(completion: .finished)
            case let .open(url):
                self.presentation.presentingViewController.dismiss(animated: true) {  
                    UIApplication
                        .shared
                        .windows
                        .first?
                        .rootViewController?
                        .present(SFSafariViewController(url: url), animated: true, completion: nil)
                }
            }

        }.store(in: &subscriptions)

        return vc
    }
}
