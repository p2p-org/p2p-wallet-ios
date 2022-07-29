// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Combine
import CombineCocoa
import KeyAppUI
import UIKit

final class EnterPhoneNumberViewController: BaseViewController {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.phoneInputRef.view?.textField?.becomeFirstResponder()
        }
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
                    with: L10n.addAPhoneToProtectYourAccount,
                    of: .text1,
                    weight: .regular,
                    alignment: .center
                )
            ).padding(.init(only: .top, inset: 19))
            UIView(height: 32)
            PhoneTextField(
                leftText: "🇦🇷",
                onLeftTap: {
                    self.viewModel.input.selectCountryTapped.send()
                },
                constantPlaceholder: "+44 7400 123456"
            ).bind(phoneInputRef)
        }
    }

    func bottomView() -> UIView {
        BEContainer {
            TextButton(title: L10n.enterTheNumberToContinue, style: .primary, size: .large).setup { button in
                button.isEnabled = false
            }.bind(continueButtonRef).onPressed { [weak self] _ in
                self?.viewModel.input.button.send()
            }
        }.padding(.init(only: .bottom, inset: 18))
    }

    override func bind() {
        super.bind()

        phoneInputRef.view?.textField?.textPublisher.removeDuplicates()
            .sink(receiveValue: { [weak self] value in
                self?.viewModel.input.phone.send(value)
            }).store(in: &store)

        viewModel.output.phone.sink { [weak self] phone in
            self?.phoneInputRef.view?.text = phone
        }.store(in: &store)

        viewModel.output.flag.sink { flag in
            self.phoneInputRef.view?.countryEmoji = flag
        }.store(in: &store)

        viewModel.output.phonePlaceholder.sink { placeholder in
            self.phoneInputRef.view?.constantPlaceholder = placeholder
        }.store(in: &store)

        viewModel.output.isButtonEnabled.sink { [weak self] isEnabled in
            self?.continueButtonRef.view?.isEnabled = isEnabled
            self?.continueButtonRef.view?.title = isEnabled ? L10n.continue : L10n.enterTheNumberToContinue
            self?.continueButtonRef.view?.trailingImage = isEnabled ? Asset.MaterialIcon.arrowForward.image : nil
        }.store(in: &store)
    }

    // MARK: -

    func configureNavBar() {
        navigationItem.title = L10n.stepOf("2", "3")

        let spacing = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacing.width = 8

        navigationItem.setLeftBarButtonItems([spacing], animated: false)

        // Right button
        let infoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        infoButton.addTarget(self, action: #selector(onInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        infoButton.tintColor = Asset.Colors.night.color
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    @objc func onInfo() {}
}

class PhoneTextField: BaseTextFieldView {
    var countryEmoji: String = "" {
        didSet {
            leftViewLabelRef.view?.text = countryEmoji
        }
    }

    var leftViewLabelRef = BERef<UILabel>()

    // MARK: -

    init(leftText: String, onLeftTap: (() -> Void)?, constantPlaceholder placeholder: String) {
        super.init(leftView: nil, rightView: nil, isBig: true)
        constantPlaceholder = placeholder
        countryEmoji = leftText
        leftView = inputLeftView()
        leftView?.onTap(onLeftTap ?? {})
        leftViewMode = .always
        textField?.keyboardType = .phonePad
        textField?.text = "+"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    private func inputLeftView() -> BEHStack {
        BEHStack {
            UILabel().withAttributedText(
                .attributedString(with: countryEmoji, of: .title1)
            ).bind(leftViewLabelRef)
            UIImageView(
                width: 8,
                height: 5,
                imageNamed: "expand-icon",
                tintColor: Asset.Colors.night.color
            ).padding(.init(only: .left, inset: 4))
        }
    }
}
