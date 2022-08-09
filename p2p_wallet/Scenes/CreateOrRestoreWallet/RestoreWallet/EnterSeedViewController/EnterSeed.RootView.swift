//
//  EnterSeed.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.11.2021.
//

import Combine
import CombineCocoa
import UIKit

extension EnterSeed {
    class RootView: BEView {
        // MARK: - Constants

        var subscriptions = [AnyCancellable]()

        // MARK: - Properties

        private let viewModel: EnterSeedViewModelType

        // MARK: - Subviews

        private let scrollView = ContentHuggingScrollView(
            scrollableAxis: .vertical,
            contentInset: .init(only: .bottom, inset: 40)
        )
        private let stackView = UIStackView(axis: .vertical, alignment: .fill, distribution: .fill)
        private let textView = ExpandableTextView()
        private let agreeTermsAndConditionsView = AgreeTermsAndConditionsView()

        private let errorLabel = UILabel(textSize: 13, textColor: .alert, numberOfLines: 0, textAlignment: .center)

        private lazy var nextButton = WLStepButton.main(text: L10n.resetAndTryAgain)
            .onTap(self, action: #selector(buttonNextDidTouch))
        private let pasteButton = UIButton(
            label: L10n.paste,
            labelFont: .systemFont(ofSize: 17, weight: .medium),
            textColor: .h5887ff
        )
        private let descriptionLabel = UILabel()

        // MARK: - Methods

        init(viewModel: EnterSeedViewModelType) {
            self.viewModel = viewModel

            super.init(frame: .zero)

            agreeTermsAndConditionsView.didTouchHyperLink = { [weak self] in
                self?.viewModel.showTermsAndConditions()
            }
        }

        override func commonInit() {
            super.commonInit()
            configureDescription()
            textView.placeholder = L10n.yourSecurityKey
            layout()
            bind()

            #if DEBUG
                if let testAccount = String.secretConfig("TEST_ACCOUNT_SEED_PHRASE")?
                    .replacingOccurrences(of: "-", with: " ")
                {
                    textView.set(text: testAccount)
                    viewModel.seedTextSubject.send(testAccount)
                }
            #endif
        }

        func startTyping() {
            textView.becomeFirstResponder()
        }

        @objc
        private func buttonNextDidTouch() {
            viewModel.goForth()
        }

        @objc
        private func buttonPasteDidTouch() {
            textView.paste()
        }

        @objc func resetAndTryAgainButtonDidTouch() {
            textView.set(text: nil)
            textView.becomeFirstResponder()
        }

        // MARK: - Layout

        private func layout() {
            let separatorView = UIView()
            separatorView.backgroundColor = .c7c7cc

            addSubview(scrollView)
            addSubview(nextButton)
            scrollView.contentView.addSubview(stackView)

            // scroll view for flexible height
            scrollView.autoPinEdge(toSuperviewSafeArea: .top, withInset: 18)
            scrollView.autoPinEdge(toSuperviewEdge: .leading)
            scrollView.autoPinEdge(toSuperviewEdge: .trailing)
            scrollView.autoPinEdge(.bottom, to: .top, of: nextButton)

            // arranged subviews
            separatorView.autoSetDimension(.height, toSize: 1)
            pasteButton.autoSetDimension(.width, toSize: 78)

            stackView.addArrangedSubviews {
                UIStackView(axis: .horizontal) {
                    textView
                    pasteButton
                }
                BEStackViewSpacing(8)
                separatorView
                BEStackViewSpacing(8)
                errorLabel
                BEStackViewSpacing(18)
                UIView.greyBannerView(alignment: .leading) {
                    descriptionLabel
                    UIButton(
                        label: L10n.whatIsASecurityKey,
                        labelFont: .systemFont(ofSize: 15, weight: .semibold),
                        textColor: .h5887ff
                    )
                        .setup { button in
                            button.addTarget(self, action: #selector(securityExplanation), for: .touchUpInside)
                        }
                }
                BEStackViewSpacing(18)
                agreeTermsAndConditionsView
            }

            pasteButton.autoMatch(.height, to: .height, of: textView)

            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))

            nextButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            nextButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
            nextButton.autoPinBottomToSuperViewSafeAreaAvoidKeyboard(inset: 18)
        }

        private func bind() {
            viewModel.errorPublisher
                .sink { [weak self] in
                    self?.errorLabel.isHidden = $0?.isEmpty ?? true
                    self?.errorLabel.text = $0
                }
                .store(in: &subscriptions)
            pasteButton.tapPublisher
                .sink { [weak self] in
                    self?.buttonPasteDidTouch()
                }
                .store(in: &subscriptions)
            textView.textView.textPublisher
                .sink { [weak self] in
                    self?.viewModel.seedTextSubject.send($0)
                }
                .store(in: &subscriptions)
            textView.textView.textPublisher
                .scan("") { [weak viewModel] previous, new -> String? in
                    guard
                        let maxWordsCount = viewModel?.maxWordsCount,
                        let newWordsCount = new?.split(separator: " ").count else { return new }
                    return newWordsCount <= maxWordsCount ? new : previous
                }
                .assign(to: \.text, on: textView.textView)
                .store(in: &subscriptions)
            viewModel.mainButtonContentPublisher
                .sink { [weak self] in
                    self?.setMainButtonContent(type: $0)
                }
                .store(in: &subscriptions)
            viewModel.seedTextPublisher
                .map { $0?.isEmpty ?? true }
                .map { !$0 }
                .sink { [weak self] in
                    self?.pasteButton.isHidden = $0
                }
                .store(in: &subscriptions)
        }

        private func configureDescription() {
            descriptionLabel.font = .systemFont(ofSize: 15, weight: .regular)
            descriptionLabel.numberOfLines = 0
            descriptionLabel.lineBreakMode = .byWordWrapping

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.17

            descriptionLabel.attributedText = NSMutableAttributedString(
                string: L10n
                    .toRecoverYourWalletEnterYourSecurityKeyS12Or24WordsSeparatedBySingleSpacesInTheCorrectOrder,
                attributes: [
                    NSAttributedString.Key.kern: -0.24,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                ]
            )
        }

        private func setMainButtonContent(type: EnterSeed.MainButtonContent) {
            let image: UIImage?
            let title: String?
            let isEnabled: Bool
            switch type {
            case .valid:
                title = L10n.saveContinue
                image = .check
                isEnabled = true
            case let .invalid(enterSeedInvalidationReason):
                image = nil
                isEnabled = false
                switch enterSeedInvalidationReason {
                case .error:
                    title = L10n.enterCorrectSecurityKey
                case .empty:
                    title = L10n.enterYourSecurityKey
                }
            }

            nextButton.isEnabled = isEnabled
            nextButton.setTitle(text: title)
            nextButton.setImage(image: image, imageSize: .init(width: 24, height: 24))
        }

        @objc private func securityExplanation() {
            viewModel.showInfo()
        }
    }
}
