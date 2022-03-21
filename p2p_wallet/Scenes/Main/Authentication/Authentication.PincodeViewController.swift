//
//  Authentication.PincodeViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2021.
//

import Foundation

extension Authentication {
    class PinCodeViewController: BEScene {
        private let viewModel: AuthenticationViewModelType

        // MARK: - Constants

        #if DEBUG
            let lockingTimeInSeconds = 10 // 10 seconds
        #else
            let lockingTimeInSeconds = 15 * 60 // 15 minutes
        #endif

        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .hidden }
        private var navigationBar = BERef<WLNavigationBar>()
        private var biometryButton = BERef<UIButton>()
        private var pincodeView = BERef<WLPinCodeView>()

        override var title: String? { didSet { navigationBar.view?.titleLabel.text = title } }
        var isIgnorable: Bool = false { didSet { navigationBar.view?.backButton.isHidden = !isIgnorable } }
        var useBiometry: Bool = true { didSet { biometryButton.alpha = isBiometryAvailable() ? 1 : 0 } }

        // MARK: - Callbacks

        var onSuccess: (() -> Void)?
        var onCancel: (() -> Void)?
        var didTapResetPincodeWithASeedPhraseButton: (() -> Void)?

        private func isBiometryAvailable() -> Bool {
            useBiometry && viewModel.isBiometryEnabled()
        }

        init(viewModel: AuthenticationViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func build() -> UIView {
            BEVStack {
                // Navigation
                WLNavigationBar()
                    .setTitle(title)
                    .setBackButtonHidden(!isIgnorable)
                    .bind(navigationBar)

                // Pincode
                WLPinCodeView(
                    correctPincode: viewModel.getCurrentPincode(),
                    maxAttemptsCount: 3,
                    bottomLeftButton: BiometricButton()
                        .setAlpha(isBiometryAvailable() ? 1 : 0)
                        .bind(biometryButton)
                        .onClick { [weak self] in self?.authWithBiometry() }
                        .setupWithType(BiometricButton.self) { button in
                            let biometryType = viewModel.getCurrentBiometryType()
                            button.setBiometricType(type: biometryType)
                        }
                )
                .bind(pincodeView)
                .setupWithType(WLPinCodeView.self) { pincodeView in
                    pincodeView.onSuccess = { [weak self] _ in
                        self?.authenticationDidComplete()
                    }

                    pincodeView.onFailedAndExceededMaxAttemps = { [weak self] in
                        self?.viewModel.setBlockedTime(Date())
                        self?.numpadDidLock()
                    }

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
                .centered(.vertical)
                
//                UILabel()
//                    .setupWithType(UILabel.self) { label in
//                        let text = NSMutableAttributedString()
//                            .text(L10n.forgotYourPIN, size: 17, weight: .medium)
//                            .text(L10n.resetIt, size: 17, weight: .medium, color: UIColor(red: 0.346, green: 0.529, blue: 1, alpha: 1))
//                        label.attributedText = text
//                    }
            }
        }

        @objc private func cancel() {
            onCancel?()
        }

        private func authenticationDidComplete() {
            onSuccess?()
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
                ) {
                    index
                    in

                    if index == 0 {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }
            }
        }

        func reset() {
            pincodeView.view?.reset()
            pincodeView.stackViewSpacing = 68
        }

        private func numpadDidLock() {
            guard let blockTime = viewModel.getBlockedTime() else { return }

            isIgnorable = false

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

                self?.pincodeView.view?.errorLabel.text = L10n
                    .weVeLockedYourWalletTryAgainIn("\(minutes) \(L10n.minutes) \(seconds) \(L10n.seconds)") + " " +
                    L10n.orResetItWithASeedPhrase

                if secondsPassed >= lockingTimeInSeconds {
                    self?.viewModel.setBlockedTime(nil)
                    self?.reset()
                    timer.invalidate()
                }
            }
        }
    }
}

private func secondsToMinutesSeconds(seconds: Int) -> (Int, Int) {
    ((seconds % 3600) / 60, (seconds % 3600) % 60)
}
