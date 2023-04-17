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

class TransactionDetailCoordinator: OldSmartCoordinator<TransactionDetailStatus> {
    let viewModel: TransactionDetailViewModel

    init(viewModel: TransactionDetailViewModel, presentingViewController: UIViewController) {
        self.viewModel = viewModel
        super.init(presentation: OldSmartCoordinatorPresentPresentation(presentingViewController))
    }

    override func build() -> UIViewController {
        // create bottomsheet
        let vc = UIBottomSheetHostingController(
            rootView: DetailTransactionView(viewModel: viewModel),
            ignoresKeyboard: true
        )
        vc.view.layer.cornerRadius = 20
        vc.onClose = { [weak self] in
            // Handle result if no action is chosen and sheet is closed by click on gray area
            self?.handleResult()
        }

        // observe action
        viewModel.action.sink { [weak self, weak vc] action in
            guard let self = self else { return }

            switch action {
            case .close:
                vc?.dismiss(animated: true)
                self.handleResult()
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
                self.handleResult()
            case let .open(url):
                self.presentation.presentingViewController.dismiss(animated: true) {
                    UIApplication
                        .shared
                        .windows
                        .first?
                        .rootViewController?
                        .present(SFSafariViewController(url: url), animated: true, completion: nil)
                }
                self.handleResult()
            }

        }.store(in: &subscriptions)
        
        // observe data to change bottomsheet's height
        viewModel.$rendableTransaction
            .sink { _ in
                DispatchQueue.main.async { [weak vc] in
                    vc?.updatePresentationLayout(animated: true)
                }
            }
            .store(in: &subscriptions)

        return vc
    }
    
    private func handleResult() {
        result.send(viewModel.rendableTransaction.status)
        result.send(completion: .finished)
    }
}
