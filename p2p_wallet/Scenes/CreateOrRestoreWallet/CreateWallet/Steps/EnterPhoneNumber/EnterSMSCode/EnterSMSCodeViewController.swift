// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Combine
import CombineCocoa
import KeyAppUI
import UIKit

final class EnterSMSCodeViewController: BaseViewController {
    private var viewModel: EnterSMSCodeViewModel

    // MARK: -

    private var smsInputRef = BERef<BaseTextFieldView>()
    private var resendButtonRef = BERef<UIButton>()
    private var continueButtonRef = BERef<TextButton>()

    var store = Set<AnyCancellable>()

    init(viewModel: EnterSMSCodeViewModel) {
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
            self.smsInputRef.view?.textField?.becomeFirstResponder()
        }
    }

    override func build() -> UIView {
        BEScrollView(contentInsets: .init(top: 130, left: 18, bottom: 18, right: 18)) {
            BEContainer {
                UILabel(numberOfLines: 0).withAttributedText(
                    .attributedString(
                        with: L10n.pleaseEnterTheCodeWeSentYou,
                        of: .title1,
                        weight: .bold,
                        alignment: .center
                    )
                )
                UIView(height: 8)
                UILabel().withAttributedText(
                    .attributedString(
                        with: "Check the number \(self.viewModel.phone)",
                        of: .text1
                    ).withForegroundColor(Asset.Colors.night.color)
                )

                BaseTextFieldView(leftView: BEView(width: 5), rightView: nil, isBig: true).bind(smsInputRef)
                    .setup { input in
                        input.textField?.keyboardType = .numberPad
                        input.constantPlaceholder = "••• •••"
                        input.textField?.textContentType = .oneTimeCode
                    }.frame(width: 173).padding(.init(only: .top, inset: 42))

                BEHStack {
                    UIButton().bind(resendButtonRef).setup { _ in }
                }.padding(.init(only: .top, inset: 10))
            }
        }
    }

    func bottomView() -> UIView {
        BEContainer {
            TextButton(
                title: L10n.continue,
                style: .primary,
                size: .large,
                trailing: Asset.MaterialIcon.arrowForward.image
            ).bind(continueButtonRef)
        }.padding(.init(only: .bottom, inset: 18))
    }

    override func bind() {
        super.bind()

        // Output
        Publishers.CombineLatest(viewModel.$resendEnabled, viewModel.$resendText)
            .sink { [weak self] isEnabled, title in
                self?.resendButtonRef.view?.setAttributedTitle(
                    NSAttributedString.attributedString(
                        with: title,
                        of: .text1,
                        weight: .regular
                    ).withForegroundColor(
                        isEnabled ? Asset.Colors.sky.color : Asset.Colors.mountain.color
                    ),
                    for: .normal
                )
                self?.resendButtonRef.view?.isEnabled = isEnabled
            }.store(in: &store)

        viewModel.$isButtonEnabled.sink { [weak self] isEnabled in
            self?.continueButtonRef.view?.isEnabled = isEnabled
        }.store(in: &store)

        if let textField = smsInputRef.view?.textField {
            viewModel.$code.map { Optional($0) }
                .assign(to: \.text, on: textField)
                .store(in: &store)

            textField.textPublisher.map { $0 ?? "" }
                .assign(to: \.code, on: viewModel)
                .store(in: &store)
        }

        viewModel.$isLoading.sink { [weak self] isLoading in
            self?.continueButtonRef.view?.isLoading = isLoading
            self?.smsInputRef.view?.textField?.isEnabled = !isLoading
        }.store(in: &store)

        viewModel.$codeError.sink { [weak self] error in
            self?.smsInputRef.view?.bottomTip(error ?? "")
            self?.smsInputRef.view?.style = error == nil ? .default : .error
            if error != nil {
                self?.smsInputRef.view?.shake()
            }
        }.store(in: &store)

        viewModel.$error.filter { $0 != nil }.sink { [weak self] error in
            guard let self = self else { return }
            let bar = SnackBar(icon: UIImage(), text: error!)
            bar.show(in: self)
        }.store(in: &store)

        // Input
        continueButtonRef.view?.onTap { [weak self] in
            self?.viewModel.buttonTaped()
        }

        resendButtonRef.view?.onTap { [weak self] in
            self?.viewModel.resendButtonTapped()
        }
    }

    func configureNavBar() {
        navigationItem.title = L10n.stepOf("2", "3")

        // Left button
        let backButton = UIBarButtonItem(
            image: UINavigationBar.appearance().backIndicatorImage,
            style: .plain,
            target: self,
            action: #selector(onBack)
        )
        backButton.tintColor = Asset.Colors.night.color

        let spacing = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacing.width = 8

        navigationItem.setLeftBarButtonItems([spacing, backButton], animated: false)

        // Right button
        let infoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        infoButton.addTarget(self, action: #selector(onInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        infoButton.tintColor = Asset.Colors.night.color
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    @objc func onBack() {
        viewModel.backTapped()
    }

    @objc func onInfo() {
        viewModel.infoTapped()
    }
}
