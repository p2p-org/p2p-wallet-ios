import Combine
import KeyAppUI
import SwiftUI
import UIKit

final class PincodeViewController: BaseViewController {
    private let viewModel: PincodeViewModel
    public var subscriptions = [AnyCancellable]()

    // MARK: - Subviews

    private var titleLabel = BERef<UILabel>()
    private var pincodeView = BERef<PinCode>()

    init(viewModel: PincodeViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pincodeView.view?.reset()
    }

    override func setUp() {
        super.setUp()
        view.backgroundColor = Asset.Colors.lime.color
        setupNavBar()
    }

    override func build() -> UIView {
        BESafeArea {
            BEVStack {
                UIImageView(
                    width: 114,
                    height: 107.adaptiveHeight,
                    image: UIImage.lockPincode,
                    contentMode: .scaleAspectFit
                )
                    .padding(.init(
                        top: 70.adaptiveHeight,
                        left: .zero,
                        bottom: 33.adaptiveHeight,
                        right: .zero
                    ))
                UIView.spacer

                UILabel(
                    font: .font(of: .title2, weight: .regular),
                    textAlignment: .center
                )
                    .bind(titleLabel)

                BEVStack {
                    PinCode(correctPincode: viewModel.pincode, bottomLeftButton: self.bottomLeftButton())
                        .setup { view in
                            view.stackViewSpacing = 20.adaptiveHeight
                            view.resetingDelayInSeconds = 1
                        }
                        .bind(pincodeView)
                        .padding(.init(only: .bottom, inset: 27.adaptiveHeight))
                    if viewModel.showForgetPin {
                        forgetPinView()
                    }
                }
                .padding(.init(only: .top, inset: 56.adaptiveHeight))
                UIView.spacer
            }
        }
    }

    func forgetPinView() -> UIView {
        UIButton(
            height: 24,
            label: L10n.forgetYouPIN,
            labelFont: UIFont.font(of: .text1),
            textColor: Asset.Colors.sky.color
        ).onTap {
            self.openForgotPIN()
        }
    }

    func bottomLeftButton() -> UIView? {
        if viewModel.showFaceid {
            let button = UIButton(width: 32, height: 32)
            button.setImage(UIImage.faceId, for: .normal)
            button.tintColor = Asset.Colors.night.color
            button.imageView?.contentMode = .scaleAspectFill
            button.onTap { [weak viewModel] in
                viewModel?.biometricsTapped()
            }
            let wrapper = BEView().frame(width: 68, height: 68)
            wrapper.addSubview(button)
            button.autoCenterInSuperView(leftInset: 18, rightInset: 18)
            return wrapper
        }
        return nil
    }

    override func bind() {
        super.bind()

        viewModel.$title.sink { [weak titleLabel] title in
            titleLabel?.text = title
        }.store(in: &subscriptions)

        pincodeView.onSuccess = { [weak viewModel] value in
            viewModel?.pincodeSuccess.send(value)
        }
        pincodeView.onFailed = { [weak viewModel] in
            viewModel?.pincodeFailed.send()
        }

        viewModel.$snackbar.sink { [weak self] model in
            guard let self = self, let model = model else { return }
            let view: UIView = self.navigationController?.view ?? self.view
            SnackBar(title: model.title, text: model.message).show(in: view, autoHide: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.pincodeView.view?.reset()
            }
            self.viewModel.snackbar = nil
        }.store(in: &subscriptions)

        viewModel.$showForgotModal
            .filter { $0 }
            .sink { [weak self] _ in
                self?.openForgotPIN(
                    text: L10n.After2MoreIncorrectAttemptsWeLlLogYouOutOfTheCurrentAccountForYourSafety
                        .youCanLogoutRightNowToCreateANewPINForTheApp,
                    height: 420.adaptiveHeight
                )
            }.store(in: &subscriptions)
    }

    private func setupNavBar() {
        addLeftButton()
        addRightButton()
    }

    private func addLeftButton() {
        guard viewModel.isBackAvailable else { return }
        guard navigationController != nil else {
            let closeButton = UIButton.close().onTap { [weak self] in
                self?.close()
            }
            view.addSubview(closeButton)
            closeButton.autoPinToTopLeftCornerOfSuperviewSafeArea(xInset: 6, yInset: -4)
            return
        }
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
        viewModel.back.send()
    }

    private func addRightButton() {
        let infoButton = UIButton()
        infoButton.addTarget(self, action: #selector(openInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        if navigationController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        } else {
            view.addSubview(infoButton)
            infoButton.autoPinToTopRightCornerOfSuperviewSafeArea(xInset: 17, yInset: 3)
        }
    }

    @objc private func openInfo() {
        viewModel.infoDidTap.send()
    }

    private var transition: PanelTransition?
    private var forgetPinViewController: UIViewController?
    private func openForgotPIN(
        text: String? = L10n.ifYouForgetYourPINYouCanLogOutAndCreateANewOneWhenYouLogInAgain,
        height: CGFloat? = nil
    ) {
        var view = ForgetPinView(text: text ?? L10n.ifYouForgetYourPINYouCanLogOutAndCreateANewOneWhenYouLogInAgain)
        view.close = { [weak self] in self?.forgetPinViewController?.dismiss(animated: true) }
        view.onLogout = { [weak self] in
            self?.forgetPinViewController?.dismiss(animated: true, completion: { [weak self] in
                self?.showAlert(
                    title: L10n.doYouWantToLogOut,
                    message: L10n.youWillNeedYourSocialAccountOrPhoneNumberToLogIn,
                    buttonTitles: [L10n.logOut, L10n.stay],
                    highlightedButtonIndex: 1,
                    destroingIndex: 0
                ) { [weak self] index in
                    guard index == 0 else { return }
                    self?.viewModel.logout()
                }
            })
        }
        transition = PanelTransition()
        transition?.containerHeight = height == nil ? view.viewHeight : (height ?? 0)
        forgetPinViewController = UIHostingController(rootView: view)
        forgetPinViewController?.view.layer.cornerRadius = 20
        forgetPinViewController?.transitioningDelegate = transition
        forgetPinViewController?.modalPresentationStyle = .custom
        transition?.dimmClicked
            .sink { [weak self] in self?.forgetPinViewController?.dismiss(animated: true) }
            .store(in: &subscriptions)
        guard let forgetPinViewController = forgetPinViewController else {
            return
        }
        present(forgetPinViewController, animated: true)
    }
}
