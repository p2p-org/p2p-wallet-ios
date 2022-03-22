//
//  Settings.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import RxSwift
import UIKit

extension Settings {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants

        let disposeBag = DisposeBag()

        // MARK: - Properties

        let viewModel: SettingsViewModelType

        // MARK: - Subviews

        private lazy var usernameLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var backupShieldImageView = UIImageView(width: 17, height: 21, image: .backupShield)
        private lazy var fiatLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var secureMethodsLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var activeLanguageLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var appearanceLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var networkLabel = UILabel(weight: .medium, textColor: .textSecondary)
        private lazy var hideZeroBalancesSwitcher: UISwitch = { [unowned self] in
            let switcher = UISwitch()
            switcher.addTarget(self, action: #selector(hideZeroBalancesSwitcherDidSwitch(sender:)), for: .valueChanged)
            return switcher
        }()

        // MARK: - Initializer

        init(viewModel: SettingsViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }

        // MARK: - Methods

        override func commonInit() {
            super.commonInit()
            scrollView.contentInset = .init(x: 0, y: 16)
            layout()
            bind()
        }

        // MARK: - Layout

        private func layout() {
            var languageTitle = L10n.language
            if languageTitle != "Language" { languageTitle += " (Language)" }

            stackView.addArrangedSubviews {
                createCell(
                    image: .settingsUsername,
                    text: L10n.username.uppercaseFirst,
                    descriptionView: usernameLabel
                )
                .withTag(0)
                .onTap(self, action: #selector(cellDidTouch(_:)))

                BEStackViewSpacing(16)

                createCell(
                    image: .settingsBackup,
                    text: L10n.backup,
                    descriptionView: backupShieldImageView
                )
                .withTag(1)
                .onTap(self, action: #selector(cellDidTouch(_:)))

                BEStackViewSpacing(1)

                createCell(
                    image: .settingsCurrency,
                    text: L10n.currency,
                    descriptionView: fiatLabel
                )
                .withTag(2)
                .onTap(self, action: #selector(cellDidTouch(_:)))

                BEStackViewSpacing(1)

                createCell(
                    image: .settingsNetwork,
                    text: L10n.network,
                    descriptionView: networkLabel
                )
                .withTag(3)
                .onTap(self, action: #selector(cellDidTouch(_:)))

                BEStackViewSpacing(1)

                createCell(
                    image: .settingsSecurity,
                    text: L10n.security,
                    descriptionView: secureMethodsLabel
                )
                .withTag(4)
                .onTap(self, action: #selector(cellDidTouch(_:)))

                BEStackViewSpacing(1)

//                createCell(
//                    image: .settingsLanguage,
//                    text: languageTitle,
//                    descriptionView: activeLanguageLabel
//                )
//                    .withTag(5)
//                    .onTap(self, action: #selector(cellDidTouch(_:)))
//
//                BEStackViewSpacing(1)

                createCell(
                    image: .settingsAppearance,
                    text: L10n.appearance,
                    descriptionView: appearanceLabel
                )
                .withTag(6)
                .onTap(self, action: #selector(cellDidTouch(_:)))

                BEStackViewSpacing(1)

                createCell(
                    image: .visibilityHide,
                    text: L10n.hideZeroBalances,
                    descriptionView: hideZeroBalancesSwitcher,
                    showRightArrow: false
                )

                //            createCell(
                //                image: .settingsFreeTransactions,
                //                text: L10n.useFreeTransactions,
                //                descriptionView: useFreeTransactionsSwitcher,
                //                showRightArrow: false
                //            )

                BEStackViewSpacing(16)

                createCell(
                    image: .settingsLogout,
                    text: L10n.logout,
                    showRightArrow: false,
                    isAlert: true
                )
                .onTap(self, action: #selector(buttonLogoutDidTouch))
            }
        }

        private func bind() {
            viewModel.usernameDriver
                .map { $0 != nil ? $0! : L10n.notYetReserved }
                .drive(usernameLabel.rx.text)
                .disposed(by: disposeBag)

            viewModel.usernameDriver
                .map { $0 == nil ? UIColor.alert : UIColor.textSecondary }
                .drive(usernameLabel.rx.textColor)
                .disposed(by: disposeBag)

            viewModel.didBackupDriver
                .map { $0 ? UIColor.attentionGreen : UIColor.alertOrange }
                .drive(backupShieldImageView.rx.tintColor)
                .disposed(by: disposeBag)

            viewModel.fiatDriver
                .map(\.name)
                .drive(fiatLabel.rx.text)
                .disposed(by: disposeBag)

            viewModel.endpointDriver
                .map(\.network.cluster)
                .drive(networkLabel.rx.text)
                .disposed(by: disposeBag)

            viewModel.securityMethodsDriver
                .map { $0.joined(separator: ", ") }
                .drive(secureMethodsLabel.rx.text)
                .disposed(by: disposeBag)

            viewModel.currentLanguageDriver
                .drive(activeLanguageLabel.rx.text)
                .disposed(by: disposeBag)

            viewModel.themeDriver
                .map { $0?.localizedString }
                .drive(appearanceLabel.rx.text)
                .disposed(by: disposeBag)

            viewModel.hideZeroBalancesDriver
                .drive(hideZeroBalancesSwitcher.rx.isOn)
                .disposed(by: disposeBag)
        }

        // MARK: - Action

        @objc func buttonLogoutDidTouch() {
            viewModel.showLogoutAlert()
        }

        @objc func cellDidTouch(_ gesture: UIGestureRecognizer) {
            guard let tag = gesture.view?.tag else { return }
            switch tag {
            case 0:
                viewModel.showOrReserveUsername()
            case 1:
                viewModel.navigate(to: .backup)
            case 2:
                viewModel.navigate(to: .currency)
            case 3:
                viewModel.navigate(to: .network)
            case 4:
                viewModel.navigate(to: .security)
            case 5:
                viewModel.navigate(to: .language)
            case 6:
                viewModel.navigate(to: .appearance)
            default:
                return
            }
        }

        @objc func hideZeroBalancesSwitcherDidSwitch(sender: UISwitch) {
            viewModel.setHideZeroBalances(sender.isOn)
        }
    }
}

private func createCell(
    image: UIImage?,
    text: String,
    descriptionView: UIView? = nil,
    showRightArrow: Bool = true,
    isAlert: Bool = false
) -> UIView {
    let stackView = UIStackView(
        axis: .horizontal,
        spacing: 16,
        alignment: .center,
        distribution: .fill,
        arrangedSubviews: [
            UIView.squareRoundedCornerIcon(image: image, tintColor: isAlert ? .alert : .iconSecondary),
            UILabel(text: text, textSize: 17, numberOfLines: 0),
        ]
    )
    if let descriptionView = descriptionView {
        stackView.addArrangedSubview(
            descriptionView
                .withContentHuggingPriority(.required, for: .horizontal)
        )
    }
    if showRightArrow {
        stackView.addArrangedSubview(
            UIView.defaultNextArrow()
        )
    }
    return stackView
        .padding(.init(x: 20, y: 6), backgroundColor: .contentBackground)
}
