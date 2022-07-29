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
    }

    override func build() -> UIView {
        BEScrollView(contentInsets: .init(top: 119, left: 18, bottom: 18, right: 18)) {
            UILabel().withAttributedText(
                .attributedString(
                    with: "What’s your number? 🤙",
                    of: .title1,
                    weight: .bold,
                    alignment: .center
                )
            )

            UILabel().withAttributedText(
                .attributedString(
                    with: "Add a phone to protect your account",
                    of: .text1,
                    weight: .regular,
                    alignment: .center
                )
            ).padding(.init(only: .top, inset: 8))

            PhoneTextField(
                leftText: "🇦🇷",
                onLeftTap: {
                    self.viewModel.input.selectCountryTapped.send()
                },
                constantPlaceholder: "+44 7400 123456"
            ).bind(phoneInputRef).padding(.init(only: .top, inset: 32))
        }
    }

    func bottomView() -> UIView {
        BEContainer {
            TextButton(title: "Enter the number to continue", style: .primary, size: .large).setup { button in
                button.isEnabled = false
            }.bind(continueButtonRef)
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
        }.store(in: &store)
    }
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
