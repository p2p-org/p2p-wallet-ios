//
//  Authentication.PincodeViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2021.
//

import Foundation

extension Authentication {
    class PincodeViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Constants

        #if DEBUG
            let lockingTimeInSeconds = 10 // 10 seconds
        #else
            let lockingTimeInSeconds = 15 * 60 // 15 minutes
        #endif

        // MARK: - Dependencies

        private let viewModel: AuthenticationViewModelType

        // MARK: - Properties

        override var title: String? { didSet { navigationBar.titleLabel.text = title } }
        var isIgnorable: Bool = false { didSet { navigationBar.backButton.isHidden = !isIgnorable } }
        var useBiometry: Bool = true { didSet { updateBiometryButtonVisibility() } }

        // MARK: - Callbacks

        var onSuccess: (() -> Void)?
        var onCancel: (() -> Void)?
        var didTapResetPincodeWithASeedPhraseButton: (() -> Void)?

        // MARK: - Subviews

        fileprivate let navigationBar = WLNavigationBar(forAutoLayout: ())
        private lazy var pincodeView = WLPinCodeView(
            correctPincode: viewModel.getCurrentPincode(),
            maxAttemptsCount: 3,
            bottomLeftButton: biometryButton
        )
        private lazy var biometryButton: UIButton? = {
            let biometryType = viewModel.getCurrentBiometryType()
            guard let icon = biometryType.icon?.withRenderingMode(.alwaysTemplate) else {
                return nil
            }
            let button = UIButton(frame: .zero)
            button.tintColor = .textBlack
            button.setImage(icon, for: .normal)
            button.contentEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12)
            button.onTap(self, action: #selector(authWithBiometry))
            return button
        }()

        private lazy var resetPinCodeWithASeedPhraseButton: UIView = {
            let button = UILabel(
                text: L10n.resetPINWithASeedPhrase,
                textSize: 13,
                weight: .semibold,
                textColor: .textSecondary,
                textAlignment: .center
            )
            .padding(.init(top: 8, left: 19, bottom: 8, right: 19), backgroundColor: .f6f6f8, cornerRadius: 12)
            .onTap(self, action: #selector(resetPincodeWithASeedPhrase))
            button.isHidden = true
            return button
        }()

        // MARK: - Initializer

        init(viewModel: AuthenticationViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func viewDidLoad() {
            super.viewDidLoad()
            // is blocking
            if (viewModel.getBlockedTime()) != nil {
                pincodeView.setBlock(true)
                pincodeView.errorLabel.isHidden = false
                numpadDidLock()
            } else {
                if isBiometryAvailable() {
                    authWithBiometry()
                }
            }
        }

        override func setUp() {
            super.setUp()
            // navigation bar
            if isIgnorable {
                navigationBar.backButton.onTap(self, action: #selector(cancel))
            }
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

            // pincode view
            let wrappedView = UIView(forAutoLayout: ())
            view.addSubview(wrappedView)
            wrappedView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            wrappedView.autoPinEdge(.top, to: .bottom, of: navigationBar)

            wrappedView.addSubview(pincodeView)
            pincodeView.autoCenterInSuperview()
            pincodeView.autoPinEdge(toSuperviewEdge: .leading, withInset: 20, relation: .greaterThanOrEqual)
            pincodeView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20, relation: .greaterThanOrEqual)

            pincodeView.onSuccess = { [weak self] _ in
                self?.authenticationDidComplete()
            }

            pincodeView.onFailedAndExceededMaxAttemps = { [weak self] in
                self?.viewModel.setBlockedTime(Date())
                self?.numpadDidLock()
            }

            // biometry button
            updateBiometryButtonVisibility()

            // reset pincode with a seed phrase
            pincodeView.addSubview(resetPinCodeWithASeedPhraseButton)
            resetPinCodeWithASeedPhraseButton.autoPinEdge(.top, to: .bottom, of: pincodeView.errorLabel, withOffset: 10)
            resetPinCodeWithASeedPhraseButton.autoAlignAxis(toSuperviewAxis: .vertical)
        }

        // MARK: - Actions

        func reset() {
            pincodeView.reset()
            pincodeView.stackViewSpacing = 68
            resetPinCodeWithASeedPhraseButton.isHidden = true
        }

        @objc private func resetPincodeWithASeedPhrase() {
            didTapResetPincodeWithASeedPhraseButton?()
        }

        @objc private func authWithBiometry() {
            viewModel.authWithBiometry { [weak self] in
                self?.authenticationDidComplete()
            } onFailure: { [weak self] in
                guard let self = self else { return }
                self.showAlert(
                    title: L10n.warning,
                    message: self.viewModel.getCurrentBiometryType().stringValue + " " + L10n.WasTurnedOff
                        .doYouWantToTurnItOn,
                    buttonTitles: [L10n.turnOn, L10n.cancel],
                    highlightedButtonIndex: 0
                ) { index in

                    if index == 0 {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }
            }
        }

        @objc private func cancel() {
            onCancel?()
        }

        private func authenticationDidComplete() {
            onSuccess?()
        }

        private func numpadDidLock() {
            guard let blockTime = viewModel.getBlockedTime() else { return }

            isIgnorable = false
            resetPinCodeWithASeedPhraseButton.isHidden = false

            pincodeView.stackViewSpacing = 108

            let lockingTimeInSeconds = lockingTimeInSeconds

            // Count down to next
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                // get current date
                let now = Date()

                // check if date > blockTime
                guard let secondsPassed = (now - blockTime).second, secondsPassed >= 0 else { return }

                let minutesAndSeconds = secondsToMinutesSeconds(seconds: lockingTimeInSeconds - secondsPassed)
                let minutes = minutesAndSeconds.0
                let seconds = minutesAndSeconds.1

                self?.pincodeView.errorLabel.text = L10n
                    .weVeLockedYourWalletTryAgainIn("\(minutes) \(L10n.minutes) \(seconds) \(L10n.seconds)") + " " +
                    L10n.orResetItWithASeedPhrase

                if secondsPassed >= lockingTimeInSeconds {
                    self?.viewModel.setBlockedTime(nil)
                    self?.reset()
                    timer.invalidate()
                }
            }
        }

        // MARK: - Helpers

        private func isBiometryAvailable() -> Bool {
            useBiometry && viewModel.isBiometryEnabled()
        }

        private func updateBiometryButtonVisibility() {
            biometryButton?.alpha = isBiometryAvailable() ? 1 : 0
        }
    }
}

private func secondsToMinutesSeconds(seconds: Int) -> (Int, Int) {
    return ((seconds % 3600) / 60, (seconds % 3600) % 60)
}
