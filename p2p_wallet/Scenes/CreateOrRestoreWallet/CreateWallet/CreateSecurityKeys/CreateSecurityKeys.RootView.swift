//
//  CreateSecurityKeys.RootView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.11.21.
//

import AnalyticsManager
import Combine
import Resolver
import TagListView
import UIKit

extension CreateSecurityKeys {
    class RootView: ScrollableVStackRootView {
        // MARK: - Dependencies

        private let viewModel: CreateSecurityKeysViewModelType
        @Injected private var analyticsManager: AnalyticsManager

        // MARK: - Properties

        private var subscriptions = [AnyCancellable]()

        // MARK: - Subviews

        private let saveToICloudButton: WLStepButton = WLStepButton.main(image: .appleLogo, text: L10n.backupToICloud)

        private let verifyManualButton: WLStepButton = WLStepButton.sub(text: L10n.verifyManually)

        private let keysView: KeysView = .init()
        private let keysViewActions: KeysViewActions = .init()
        private let agreeTermsAndConditions = AgreeTermsAndConditionsView()

        // MARK: - Initializers

        init(viewModel: CreateSecurityKeysViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()

            agreeTermsAndConditions.didTouchHyperLink = { [weak viewModel] in
                viewModel?.termsAndConditions()
            }
            layout()
            bind()
        }

        // MARK: - Methods

        // MARK: - Layout

        private func layout() {
            // content
            scrollView.contentInset.top = 56
            scrollView.contentInset.bottom = 120
            stackView.addArrangedSubviews {
                keysView
                keysViewActions
                BEStackViewSpacing(10)
                agreeTermsAndConditions
            }

            // bottom button
            let bottomStack = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
                saveToICloudButton
                verifyManualButton
            }
            bottomStack.backgroundColor = .background
            addSubview(bottomStack)
            bottomStack.autoPinEdgesToSuperviewSafeArea(
                with: .init(top: 0, left: 18, bottom: 20, right: 18),
                excludingEdge: .top
            )
        }

        func bind() {
            viewModel.phrasesDriver
                .assign(to: \.keys, on: keysView)
                .store(in: &subscriptions)

            keysViewActions.onCopy
                .sink { [weak self] in self?.viewModel.copyToClipboard() }
                .store(in: &subscriptions)

            keysViewActions.onRefresh
                .sink { [weak self] in self?.viewModel.renewPhrases() }
                .store(in: &subscriptions)

            keysViewActions.onSave
                .sink { [weak self] in self?.saveToPhoto() }
                .store(in: &subscriptions)

            verifyManualButton.onTap(self, action: #selector(verifyPhrase))
            saveToICloudButton.onTap(self, action: #selector(saveToICloud))
        }

        // MARK: - Actions

        @objc func saveToICloud() {
            viewModel.saveToICloud()
        }

        @objc func verifyPhrase() {
            viewModel.verifyPhrase()
        }

        func saveToPhoto() {
            analyticsManager.log(event: .backingUpSaving)
            viewModel.saveKeysImage(keysView.asImage())
        }
    }
}
