//
//  ProcessTransaction.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/03/2022.
//

import BEPureLayout
import Combine
import Foundation
import UIKit

extension ProcessTransaction {
    final class ViewController: BaseVC {
        // MARK: - Properties

        private var subscriptions = [AnyCancellable]()
        private let viewModel: ProcessTransactionViewModelType
        private var detailViewController: TransactionDetail.ViewController!
        private var statusViewController: Status.ViewController!
        private var statusViewControllerShown = false

        // MARK: - Handlers

        var doneHandler: (() -> Void)?
        var makeAnotherTransactionHandler: (() -> Void)?
        var specificErrorHandler: ((Swift.Error) -> Void)?

        // MARK: - Initializer

        init(viewModel: ProcessTransactionViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func setUp() {
            super.setUp()
            Task {
                try? await viewModel.sendAndObserveTransaction()
            }
            view.onTap { [weak view] in
                view?.endEditing(true)
            }
        }

        override func bind() {
            super.bind()

            viewModel.observingTransactionIndexDriver
                .filter { $0 != nil }
                .map { $0! }
                .removeDuplicates()
                .sink { [weak self] index in
                    guard let self = self else { return }
                    self.detailViewController?.removeFromParent()
                    let vm = TransactionDetail.ViewModel(observingTransactionIndex: index)
                    self.detailViewController = TransactionDetail.ViewController(viewModel: vm)
                    self.add(child: self.detailViewController)
                }
                .store(in: &subscriptions)

            viewModel.navigationDriver
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if !statusViewControllerShown {
                statusViewController = .init(viewModel: viewModel)
                statusViewController.doneHandler = doneHandler
                present(statusViewController, interactiveDismissalType: .none, completion: nil)
                statusViewControllerShown = true
            }
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .makeAnotherTransaction:
                statusViewController.dismiss(animated: true) {
                    self.makeAnotherTransactionHandler?()
                }
            case let .specificErrorHandler(error):
                statusViewController.dismiss(animated: true) {
                    self.specificErrorHandler?(error)
                }
            default:
                break
            }
        }
    }
}
