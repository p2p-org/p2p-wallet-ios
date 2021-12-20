//
//  EnterSeed.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.11.2021.
//

import UIKit
import RxSwift

extension EnterSeed {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: EnterSeedViewModelType

        // MARK: - Subviews
        private let scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: .init(only: .bottom, inset: 40))
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
                viewModel.seedTextSubject.accept(testAccount)
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

            let navigationBar = EnterSeed.NavigationBar(
                backHandler: { [weak viewModel] in
                    viewModel?.goBack()
                },
                infoHandler: { [weak viewModel] in
                    viewModel?.showInfo()
                }
            )

            addSubview(navigationBar)
            addSubview(scrollView)
            addSubview(nextButton)
            scrollView.contentView.addSubview(stackView)

            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

            // scroll view for flexible height
            scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 18)
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
                UIView.greyBannerView {
                    descriptionLabel
                }
                BEStackViewSpacing(18)
                agreeTermsAndConditionsView
            }

            pasteButton.autoMatch(.height, to: .height, of: textView)

            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))

            nextButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            nextButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
            nextButton.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
        }
        
        private func bind() {
            viewModel.errorDriver
                .drive(onNext: { [weak self] in
                    self?.errorLabel.isHidden = $0?.isEmpty ?? true
                    self?.errorLabel.text = $0
                })
                .disposed(by: disposeBag)
            pasteButton.rx.tap
                .bind { [weak self] in
                    self?.buttonPasteDidTouch()
                }
                .disposed(by: disposeBag)
            textView.rxText
                .bind { [weak self] in
                    self?.viewModel.seedTextSubject.accept($0)
                }
                .disposed(by: disposeBag)
            viewModel.mainButtonContentDriver
                .drive(onNext: { [weak self] in
                    self?.setMainButtonContent(type: $0)
                })
                .disposed(by: disposeBag)
            viewModel.seedTextDriver
                .map { $0?.isEmpty ?? true }
                .map { !$0 }
                .drive(onNext: { [weak self] in
                    self?.pasteButton.isHidden = $0
                })
                .disposed(by: disposeBag)
        }

        private func configureDescription() {
            descriptionLabel.font = .systemFont(ofSize: 15, weight: .regular)
            descriptionLabel.numberOfLines = 0
            descriptionLabel.lineBreakMode = .byWordWrapping

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.17

            descriptionLabel.attributedText = NSMutableAttributedString(
                string: L10n.toRecoverYourWalletEnterYourSecurityKeyS12Or24WordsSeparatedBySingleSpacesInTheCorrectOrder,
                attributes: [
                    NSAttributedString.Key.kern: -0.24,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle
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
            case .invalid(let enterSeedInvalidationReason):
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
    }
}
