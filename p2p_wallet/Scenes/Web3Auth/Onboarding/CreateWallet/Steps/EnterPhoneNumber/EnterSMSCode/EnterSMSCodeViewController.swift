import BEPureLayout
import Combine
import KeyAppUI
import UIKit

final class EnterSMSCodeViewController: BaseOTPViewController {
    private var viewModel: EnterSMSCodeViewModel

    // MARK: -

    private var smsInputRef = BERef<BaseTextFieldView>()
    private var resendButtonRef = BERef<UIButton>()
    private var continueButtonRef = BERef<TextButton>()
    
    private var disableRightButton: Bool

    var store = Set<AnyCancellable>()

    init(viewModel: EnterSMSCodeViewModel, disableRightButton: Bool = false) {
        self.viewModel = viewModel
        self.disableRightButton = disableRightButton
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
        openKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideKeyboard()
    }

    override func build() -> UIView {
        BEScrollView(contentInsets: .init(top: 30, left: 18, bottom: 18, right: 18)) {
            BEContainer {
                UILabel(numberOfLines: 0).withAttributedText(
                    .attributedString(
                        with: L10n.theCodeFromSMS,
                        of: .title1,
                        weight: .bold,
                        alignment: .center
                    )
                )
                UIView(height: 10)
                UILabel().withAttributedText(
                    .attributedString(
                        with: "Check the number \(self.viewModel.phone)",
                        of: .text1
                    )
                    .withForegroundColor(.init(resource: .night))
                )

                BaseTextFieldView(leftView: BEView(width: 7), rightView: nil, isBig: true).bind(smsInputRef)
                    .setup { input in
                        input.textField?.keyboardType = .numberPad
                        input.constantPlaceholder = "••• •••"
                        input.textField?.textContentType = .oneTimeCode
                    }.frame(width: 180).padding(.init(only: .top, inset: 28))

                BEHStack {
                    UIButton().bind(resendButtonRef).setup { _ in }
                }.padding(.init(only: .top, inset: 7))
            }
        }
    }

    func bottomView() -> UIView {
        BEContainer {
            TextButton(
                title: L10n.enterTheCodeToContinue,
                style: .primary,
                size: .large,
                trailing: UIImage(resource: .arrowForward)
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
                        .init(resource: isEnabled ? .sky : .mountain)
                    ),
                    for: .normal
                )
                self?.resendButtonRef.view?.isEnabled = isEnabled
            }.store(in: &store)

        viewModel.$isButtonEnabled.sink { [weak self] isEnabled in
            self?.continueButtonRef.view?.isEnabled = isEnabled
            self?.continueButtonRef.view?.title = isEnabled ? L10n.continue : L10n.enterTheCodeToContinue
            self?.continueButtonRef.view?.trailingImage = isEnabled ? UIImage(resource: .arrowForward) : nil
        }.store(in: &store)

        if let textField = smsInputRef.view?.textField {
            viewModel.$code.map { Optional($0) }
                .assignWeak(to: \.text, on: textField)
                .store(in: &store)

            textField.textPublisher.map { $0 ?? "" }
                .assignWeak(to: \.code, on: viewModel)
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
                self?.openKeyboard()
            }
        }.store(in: &store)

        viewModel.$error.filter { $0 != nil }.sink { [weak self] error in
            self?.showError(error: error)
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
        // Left button
        let backButton = UIBarButtonItem(
            image: .init(resource: .arrowBackIos),
            style: .plain,
            target: self,
            action: #selector(onBack)
        )
        backButton.tintColor = .init(resource: .night)
        navigationItem.leftBarButtonItem = backButton

        if !disableRightButton {
            // Right button
            let infoButton = UIButton()
            infoButton.addTarget(self, action: #selector(onInfo), for: .touchUpInside)
            infoButton.setImage(.init(resource: .helpOutline), for: .normal)
            infoButton.contentMode = .scaleAspectFill
            infoButton.tintColor = .init(resource: .night)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        }
    }

    @objc func onBack() {
        viewModel.backTapped()
    }

    @objc func onInfo() {
        viewModel.infoTapped()
    }

    private func openKeyboard() {
        smsInputRef.view?.textField?.becomeFirstResponder()
    }
}
