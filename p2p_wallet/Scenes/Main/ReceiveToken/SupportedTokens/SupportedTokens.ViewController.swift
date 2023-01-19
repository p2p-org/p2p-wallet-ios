//
//  SupportedTokens.ViewController.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.01.2022.
//

import Foundation
import UIKit

extension SupportedTokens {
    final class ViewController: BaseVC {
        // MARK: - Properties

        private let viewModel: ViewModel

        private lazy var rootView = RootView(viewModel: viewModel)

        // MARK: - Initializer

        init(viewModel: ViewModel) {
            self.viewModel = viewModel

            super.init()

            title = L10n.listOfSupportedTokens
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()

            let stackView = UIStackView(
                axis: .vertical,
                spacing: 0,
                alignment: .fill,
                distribution: .fill,
                arrangedSubviews: [
                    ModalNavigationBar(
                        title: title,
                        rightButtonTitle: L10n.close,
                        closeHandler: { [weak self] in
                            self?.dismiss(animated: true)
                        }
                    ),
                    rootView,
                ]
            )

            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }
    }
}
