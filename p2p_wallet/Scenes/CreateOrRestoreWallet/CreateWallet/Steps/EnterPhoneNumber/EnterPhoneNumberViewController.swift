// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Combine
import CombineCocoa
import KeyAppUI
import UIKit

final class EnterPhoneNumberViewController: BaseOTPViewController {
    private var viewModel: EnterPhoneNumberViewModel

    // MARK: -

    private var phoneInputRef = BERef<PhoneTextField>()
    private var continueButtonRef = BERef<TextButton>()

    var store = Set<AnyCancellable>()

    init(viewModel: EnterPhoneNumberViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func setUp() {
        super.setUp()

        let button = bottomView()
        view.addSubview(button)
        button.autoPinBottomToSuperViewSafeAreaAvoidKeyboard(inset: 0)
        button.autoPinEdge(toSuperviewEdge: .leading, withInset: 18)
        button.autoPinEdge(toSuperviewEdge: .trailing, withInset: 18)

        configureNavBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        phoneInputRef.view?.textField?.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        phoneInputRef.view?.textField?.resignFirstResponder()
    }

    private var topContentInset = {
        UIScreen.main.bounds.height / 812.0 * 36
    }

    override func build() -> UIView {
        BEScrollView(contentInsets: .init(top: topContentInset(), left: 18, bottom: 18, right: 18)) {
            UILabel().withAttributedText(
                .attributedString(
                    with: L10n.whatSYourNumber🤙,
                    of: .title1,
                    weight: .bold,
                    alignment: .center
                )
            )

            UILabel().withAttributedText(
                .attributedString(
                    with: viewModel.subtitle,
                    of: .text1,
                    weight: .regular,
                    alignment: .center
                )
            ).padding(.init(only: .top, inset: 19))
            UIView(height: 32)
            PhoneTextField(
                leftText: viewModel.selectedCountry.emoji ?? "",
                onLeftTap: { [weak viewModel] in
                    viewModel?.selectCountryTap()
                }, onPaste: {  [weak viewModel] in
                    viewModel?.onPaste()
                }
            ).bind(phoneInputRef)
        }
    }

    func bottomView() -> UIView {
        BEContainer {
            TextButton(title: L10n.enterTheNumberToContinue, style: .primary, size: .large).setup { button in
                button.isEnabled = false
            }.bind(continueButtonRef).onPressed { [weak self] _ in
                self?.viewModel.buttonTaped()
            }
        }.padding(.init(only: .bottom, inset: 18))
    }

    override func bind() {
        super.bind()

        if let phone = phoneInputRef.view {
            viewModel.$phone
                .assign(to: \.text, on: phone)
                .store(in: &store)

            phone.textField?
                .textPublisher.assign(to: \.phone, on: viewModel)
                .store(in: &store)

            viewModel.$flag
                .assign(to: \.countryEmoji, on: phone)
                .store(in: &store)

            viewModel.$phonePlaceholder
                .assign(to: \.constantPlaceholder, on: phone)
                .store(in: &store)

            viewModel.$inputError.sink { error in
                phone.bottomTip(error ?? "")
                phone.style = error == nil ? .default : .error
            }.store(in: &store)
        }

        viewModel.$isButtonEnabled.sink { [weak self] isEnabled in
            self?.continueButtonRef.view?.isEnabled = isEnabled
            self?.continueButtonRef.view?.title = isEnabled ? L10n.continue : L10n.enterTheNumberToContinue
            self?.continueButtonRef.view?.trailingImage = isEnabled ? Asset.MaterialIcon.arrowForward.image : nil
        }.store(in: &store)

        viewModel.$isLoading.sink { [weak self] isLoading in
            self?.continueButtonRef.view?.isLoading = isLoading
        }.store(in: &store)

        viewModel.$error.sink { [weak self] error in
            guard let error = error else { return }
            self?.showError(error: error)
        }.store(in: &store)
    }

    // MARK: -

    func configureNavBar() {
        addLeftButton()
        // Right button
        let infoButton = UIButton()
        infoButton.addTarget(self, action: #selector(onInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        infoButton.tintColor = Asset.Colors.night.color
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    private func addLeftButton() {
        guard viewModel.isBackAvailable else { return }
        let backButton = UIBarButtonItem(
            image: Asset.MaterialIcon.arrowBackIos.image,
            style: .plain,
            target: self,
            action: #selector(onBack)
        )
        backButton.tintColor = Asset.Colors.night.color
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func onBack() {
        viewModel.coordinatorIO.back.send()
    }

    @objc func onInfo() {
        viewModel.infoClicked()
    }
}

class PhoneTextField: BaseTextFieldView {
    var countryEmoji: String = "" {
        didSet {
            leftViewLabelRef.view?.text = countryEmoji
        }
    }

    var leftViewLabelRef = BERef<UILabel>()
    let onPaste: (() -> Void)?

    // MARK: -

    init(leftText: String, onLeftTap: (() -> Void)?, onPaste: (() -> Void)?) {
        self.onPaste = onPaste
        super.init(leftView: nil, rightView: nil, isBig: true)
        countryEmoji = leftText
        leftView = inputLeftView()
        leftView?.onTap(onLeftTap ?? {})
        leftViewMode = .always
        textField?.keyboardType = .phonePad
        textField?.text = "+"
        textField?.font = UIFont.font(of: .title1, weight: .bold)
        (textField as? TextField)?.onPaste = onPaste
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    private func inputLeftView() -> BEHStack {
        BEHStack(alignment: .center) {
            UILabel()
                .withAttributedText(.attributedString(with: countryEmoji, of: .title1))
                .bind(leftViewLabelRef)

            UIImageView(
                width: 8,
                height: 5,
                imageNamed: "expand-icon",
                tintColor: Asset.Colors.night.color
            ).padding(.init(only: .left, inset: 4))
        }
    }
}
