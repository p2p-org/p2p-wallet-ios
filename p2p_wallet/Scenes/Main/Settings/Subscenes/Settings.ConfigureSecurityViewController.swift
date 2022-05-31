//
//  Settings.ConfigureSecurityViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation
import LocalAuthentication
import SolanaSwift

extension Settings {
    class ConfigureSecurityViewController: BaseViewController {
        lazy var biometrySwitcher: UISwitch = {
            let switcher = UISwitch()
            switcher.tintColor = .textWhite
            //        switcher.onTintColor = .h5887ff
            switcher.addTarget(self, action: #selector(switcherDidChange(_:)), for: .valueChanged)
            return switcher
        }()

        // MARK: - Dependencies

        let viewModel: SettingsViewModelType

        // MARK: - Initializers

        init(viewModel: SettingsViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func setUp() {
            super.setUp()
            navigationBar.titleLabel.text = L10n.security
            stackView.setCustomSpacing(10, after: stackView.arrangedSubviews[1]) // separator
            stackView.addArrangedSubviews {
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                    UIView.squareRoundedCornerIcon(image: .settingsPincode)
                    UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                        UILabel(text: L10n.pinCode, weight: .medium)
                        UILabel(
                            text: L10n.defaultSecureCheck,
                            textSize: 12,
                            textColor: .textSecondary,
                            numberOfLines: 0
                        )
                    }
                    UIView.defaultNextArrow()
                }
                .padding(.init(x: 20, y: 14), backgroundColor: .contentBackground)
                .onTap(self, action: #selector(buttonChangePinCodeDidTouch))

                UIView.spacer
            }

            let biometryMethod = LABiometryType.current
            if !biometryMethod.stringValue.isEmpty {
                var index = 2
                stackView.insertArrangedSubviews(at: &index) {
                    UIView.row([
                        UIView.squareRoundedCornerIcon(image: biometryMethod.icon),
                        UIView.col([
                            UILabel(text: LABiometryType.current.stringValue, weight: .medium),
                            UILabel(
                                text: L10n.willBeAsAPrimarySecureCheck,
                                textSize: 12,
                                textColor: .textSecondary,
                                numberOfLines: 0
                            ),
                        ]).with(spacing: 5),
                        biometrySwitcher,
                    ])
                        .with(spacing: 16, alignment: .center, distribution: .fill)
                        .padding(.init(x: 20, y: 14), backgroundColor: .contentBackground)

                    BEStackViewSpacing(1)
                }
            }

            biometrySwitcher.isOn = Defaults.isBiometryEnabled
        }

        @objc func switcherDidChange(_ switcher: UISwitch) {
            viewModel.setEnabledBiometry(switcher.isOn) { [weak self] error in
                self?.showError(error ?? SolanaSDK.Error.unknown)
                self?.biometrySwitcher.isOn.toggle()
            }
        }

        @objc func buttonChangePinCodeDidTouch() {
            viewModel.changePincode()
        }
    }
}
