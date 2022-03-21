//
//  ReserveName.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 26.11.2021.
//

import RxCocoa
import RxSwift
import UIKit

extension ReserveName {
    class RootView: BEView {
        // MARK: - Constants

        private let disposeBag = DisposeBag()

        // MARK: - Properties

        private let viewModel: ReserveNameViewModelType

        // MARK: - Subviews

        private let scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: .init(only: .bottom, inset: 40))
        private let stackView = UIStackView(axis: .vertical, alignment: .fill, distribution: .fill)

        private let textView = ExpandableTextView(
            changesFilter: ReserveTextViewChangesFilter(),
            limitOfLines: 1
        )
        private let usernameHintLabel = TopAlignLabel(textSize: 13, weight: .regular, numberOfLines: 0)
        private let usernameLoadingView = LoadingView()
        private lazy var nextButton = WLStepButton.main(text: L10n.resetAndTryAgain)
            .onTap(self, action: #selector(buttonNextDidTouch))
        private let descriptionLabel = UILabel()
        private let agreeTermsAndPolicyView = AgreeTermsAndPolicyView()

        // MARK: - Methods

        init(viewModel: ReserveNameViewModelType) {
            self.viewModel = viewModel

            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()

            configureSubviews()
            layout()
            bind()
        }

        func startTyping() {
            textView.becomeFirstResponder()
        }

        private func configureSubviews() {
            textView.placeholder = L10n.username
            textView.setPostfix(text: .nameServiceDomain)
            configureDescription()
            configureAgreeTermsAndPolicyView()
        }

        @objc
        private func buttonNextDidTouch() {
            viewModel.goForth()
        }

        private func configureAgreeTermsAndPolicyView() {
            switch viewModel.kind {
            case .reserveCreateWalletPart:
                agreeTermsAndPolicyView.didTouchTermsOfUse = { [weak viewModel] in
                    viewModel?.showTermsOfUse()
                }
                agreeTermsAndPolicyView.didTouchPrivacyPolicy = { [weak viewModel] in
                    viewModel?.showPrivacyPolicy()
                }
            case .independent:
                agreeTermsAndPolicyView.isHidden = true
            }
        }

        private func configureDescription() {
            descriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            descriptionLabel.numberOfLines = 0
            descriptionLabel.lineBreakMode = NSLineBreakMode.byWordWrapping

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.17

            descriptionLabel.attributedText = NSMutableAttributedString(
                string: L10n
                    .P2PUsernameIsYourPublicAddressWhichAllowsYouToReceiveAnyTokenEvenIfYouDonTHaveItInTheWalletList
                    .itIsVitalYouSelectTheExactUsernameYouWantAsOnceSetYouCannotChangeIt,
                attributes: [
                    NSAttributedString.Key.kern: -0.24,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                ]
            )
        }

        private func layout() {
            let separatorView = UIView()
            separatorView.backgroundColor = .c7c7cc

            let canSkip: Bool

            switch viewModel.kind {
            case .reserveCreateWalletPart:
                canSkip = true
            case .independent:
                canSkip = false
            }

            let navigationBar = NavigationBar(
                canSkip: canSkip,
                backHandler: { [weak viewModel] in
                    viewModel?.goBack()
                },
                skipHandler: { [weak viewModel] in
                    viewModel?.skipButtonPressed()
                }
            )

            let mainButtonView = BottomFixedView(content: nextButton)

            addSubview(navigationBar)
            addSubview(scrollView)
            addSubview(mainButtonView)
            scrollView.contentView.addSubview(stackView)

            mainButtonView.setConstraints()
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

            // scroll view for flexible height
            scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 18)
            scrollView.autoPinEdge(toSuperviewEdge: .leading)
            scrollView.autoPinEdge(toSuperviewEdge: .trailing)
            scrollView.autoPinEdge(.bottom, to: .top, of: mainButtonView)

            usernameHintLabel.autoSetDimension(.height, toSize: 32)
            separatorView.autoSetDimension(.height, toSize: 1)

            stackView.addArrangedSubviews {
                textView
                BEStackViewSpacing(8)
                separatorView
                BEStackViewSpacing(8)
                usernameHintLabel
                BEStackViewSpacing(12)
                usernameLoadingView
                BEStackViewSpacing(12)
                UIView.greyBannerView {
                    descriptionLabel
                }
                BEStackViewSpacing(18)
                agreeTermsAndPolicyView
            }

            usernameLoadingView.autoMatch(.height, to: .height, of: usernameHintLabel)

            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))
        }

        private func bind() {
            viewModel.textFieldStateDriver
                .drive { [weak self] in
                    self?.setHintContent(for: $0)
                }
                .disposed(by: disposeBag)

            textView.rxText
                .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .bind(to: viewModel.textFieldTextSubject)
                .disposed(by: disposeBag)

            viewModel.mainButtonStateDriver
                .drive { [weak self] in
                    self?.setMainButtonContent(for: $0)
                }
                .disposed(by: disposeBag)

            viewModel.isLoadingDriver
                .skip(1)
                .drive { [weak self] isPosting in
                    isPosting ? self?.showIndetermineHud() : self?.hideHud()
                }
                .disposed(by: disposeBag)

            viewModel.usernameValidationLoadingDriver
                .drive { [weak self] isLoading in
                    self?.setHintIsLoading(isLoading)
                }
                .disposed(by: disposeBag)
        }

        private func setHintIsLoading(_ isLoading: Bool) {
            usernameLoadingView.isHidden = !isLoading
            usernameHintLabel.isHidden = isLoading
        }

        private func setHintContent(for state: TextFieldState) {
            let color: UIColor
            let text: String

            switch state {
            case let .available(name):
                text = L10n.isAvailable(name)
                color = .h34c759
            case let .unavailable(name):
                text = L10n.isUnavailable(name)
                color = .ff3b30
            case .empty:
                text = L10n.noMoreThan15AlphanumericalLatinLowercaseCharactersAndDashes
                color = .h8e8e93
            }

            usernameHintLabel.textColor = color
            usernameHintLabel.text = text
        }

        private func setMainButtonContent(for state: MainButtonState) {
            let image: UIImage?
            let title: String?
            let isEnabled: Bool

            switch state {
            case .empty:
                image = nil
                isEnabled = false

                switch viewModel.kind {
                case .reserveCreateWalletPart:
                    title = L10n.enterUsernameOrSkip
                case .independent:
                    title = L10n.enterUsername
                }
            case .unavailableUsername:
                image = nil
                isEnabled = false
                title = L10n.chooseAvailableUsername
            case .canContinue:
                image = .check
                isEnabled = true
                title = L10n.saveContinue
            }

            nextButton.isEnabled = isEnabled
            nextButton.setTitle(text: title)
            nextButton.setImage(image: image, imageSize: .init(width: 24, height: 24))
        }
    }
}
