//
//  Settings.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import Foundation
import UIKit

extension Settings {
    class ViewController: BEScene {
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        let viewModel: SettingsViewModelType

        init(viewModel: SettingsViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func setUp() {
            super.setUp()
            view.backgroundColor = .settingsBackground
        }

        override func build() -> UIView {
            BEVStack {
                NewWLNavigationBar(initialTitle: L10n.settings, separatorEnable: false)
                    .onBack { [unowned self] in self.back() }
                    .backIsHidden(!viewModel.canGoBack)

                BEScrollView(contentInsets: .init(x: 18, y: 18), spacing: 36) {
                    // Acount section
                    SectionView(title: L10n.profile) {
                        // Profile
                        CellView(
                            icon: .profileIcon,
                            title: UILabel(text: L10n.username.onlyUppercaseFirst()),
                            trailing: UILabel(textSize: 15).setupWithType(UILabel.self) { label in
                                viewModel.usernameDriver.map { $0 != nil ? $0! : L10n.notYetReserved }
                                    .drive(label.rx.text)
                                    .disposed(by: disposeBag)
                                viewModel.usernameDriver.map { $0 != nil ? UIColor.textBlack : UIColor.ff3b30 }
                                    .drive(label.rx.textColor)
                                    .disposed(by: disposeBag)
                            }
                        )
                        .onTap { [unowned self] in
                            if self.viewModel.getUsername() == nil {
                                viewModel.showOrReserveUsername()
                            } else {
                                viewModel.navigate(to: .username)
                            }
                        }

                        // Contact
                        // CellView(icon: .contactIcon, title: L10n.contact.onlyUppercaseFirst())

                        // History
                        // CellView(icon: .historyIcon, title: L10n.history.onlyUppercaseFirst())

                        // Sign out button
                        BECenter {
                            UILabel(text: "Sign out", textColor: .ff3b30)
                        }
                        .frame(height: 60)
                        .onTap { [unowned self] in viewModel.showLogoutAlert() }
                    }

                    // Security & network section
                    SectionView(title: L10n.securityNetwork) {
                        // Backup
                        CellView(
                            icon: .backupIcon,
                            title: UILabel(text: L10n.backup.onlyUppercaseFirst()),
                            trailing: UILabel(textSize: 15).setupWithType(UILabel.self) { label in
                                // Text
                                viewModel.didBackupDriver
                                    .map { $0 ? L10n.backupIsReady : L10n.backupRequired }
                                    .drive(label.rx.text)
                                    .disposed(by: disposeBag)
                                // Color
                                viewModel.didBackupDriver
                                    .map { $0 ? UIColor.h34c759 : UIColor.ff3b30 }
                                    .drive(label.rx.textColor)
                                    .disposed(by: disposeBag)
                            }
                        )
                        .onTap { [unowned self] in viewModel.navigate(to: .backup) }

                        // Pin
                        CellView(
                            icon: .pinIcon,
                            title: UILabel(text: L10n.yourPIN.uppercaseFirst),
                            trailing: UILabel(text: L10n.pinIsSet, textSize: 15, textColor: .h34c759)
                        ).onTap { [unowned self] in viewModel.changePincode() }

                        // Face id
                        CellView(
                            icon: .faceIdIcon,
                            title: UILabel().setupWithType(UILabel.self) { view in
                                viewModel.biometryTypeDriver.map {
                                    switch $0 {
                                    case .touch: return L10n.touchID
                                    default: return L10n.faceID
                                    }
                                }.drive(view.rx.text)
                                    .disposed(by: disposeBag)
                            },
                            trailing: UISwitch().setupWithType(UISwitch.self) { switcher in
                                viewModel.isBiometryAvailableDriver.drive(switcher.rx.isEnabled)
                                    .disposed(by: disposeBag)
                                viewModel.isBiometryEnabledDriver.drive(switcher.rx.value).disposed(by: disposeBag)
                                switcher.rx
                                    .controlEvent(.valueChanged)
                                    .withLatestFrom(switcher.rx.value)
                                    .subscribe { [unowned self] value in
                                        self.viewModel.setEnabledBiometry(value) { [weak self] error in
                                            guard let error = error else { return }
                                            self?.showError(error)
                                        }
                                    }
                                    .disposed(by: disposeBag)
                            },
                            nextArrowEnable: false
                        )

                        // Transaction
                        /*
                         CellView(
                             icon: .securityIcon,
                             title: L10n.confirmTransactions.onlyUppercaseFirst(),
                             trailing: UISwitch(),
                             nextArrowEnable: false
                         )
                         */

                        // Network
                        CellView(icon: .networkIcon, title: UILabel(text: L10n.network.onlyUppercaseFirst()))
                            .onTap { [unowned self] in viewModel.navigate(to: .network) }

                        /*
                         // Fee
                         CellView(
                             icon: .payFeeIcon,
                             title: L10n.payFeesWith.onlyUppercaseFirst(),
                             trailing: UILabel(text: "SOL"),
                             dividerEnable: false
                         )
                         */
                    }

                    // Appearance section
                    SectionView(title: L10n.appearance) {
                        /*
                         // Notification
                         CellView(
                             icon: .notification,
                             title: L10n.notifications.onlyUppercaseFirst(),
                             trailing: UISwitch(),
                             nextArrowEnable: false
                         )
                         */

                        // Currency
                        CellView(
                            icon: .currency,
                            title: UILabel(text: L10n.currency.onlyUppercaseFirst()),
                            trailing: UILabel(text: L10n.system, textColor: .secondaryLabel)
                                .setupWithType(UILabel.self) { label in
                                    viewModel.fiatDriver
                                        .map { fiat in fiat.name }
                                        .drive(label.rx.text)
                                        .disposed(by: disposeBag)
                                }
                        )
                        .onTap { [unowned self] in self.viewModel.navigate(to: .currency) }

                        // Appearance
                        CellView(
                            icon: .appearanceIcon,
                            title: UILabel(text: L10n.appearance.onlyUppercaseFirst()),
                            trailing: UILabel(text: L10n.system, textColor: .secondaryLabel)
                        ).onTap { [unowned self] in viewModel.navigate(to: .appearance) }

                        // Hide zero balance

                        CellView(
                            icon: .hideZeroBalance,
                            title: UILabel(text: L10n.hideZeroBalances.onlyUppercaseFirst()),
                            trailing: UISwitch().setupWithType(UISwitch.self) { switcher in
                                viewModel.hideZeroBalancesDriver.drive(switcher.rx.value).disposed(by: disposeBag)
                                switcher.rx.controlEvent(.valueChanged)
                                    .withLatestFrom(switcher.rx.value)
                                    .subscribe { [unowned self] in viewModel.setHideZeroBalances($0) }
                                    .disposed(by: disposeBag)
                            },
                            nextArrowEnable: false
                        )

                        /*
                         // App icon
                         CellView(
                             icon: .appIcon,
                             title: L10n.appIcon,
                             trailing: UILabel(text: L10n.classic.onlyUppercaseFirst(), textColor: .secondaryLabel)
                         )

                         // Swipes
                         CellView(
                             icon: .swipesIcon,
                             title: L10n.swapping.onlyUppercaseFirst(),
                             dividerEnable: false
                         )
                         */
                    }

                    /*
                     // Appearance section
                     SectionView {
                         // Ask
                         CellView(icon: .askIcon, title: L10n.askAQuestionRequestAFeature)

                         // Version
                         CellView(icon: .appVersionIcon, title: L10n.appVersion, dividerEnable: false)
                     }
                     */
                }
            }
        }

        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)

            viewModel.logoutAlertSignal
                .emit(onNext: { [weak self] in
                    self?.showAlert(
                        title: L10n.areYouSureYouWantToSignOut,
                        message: L10n.withoutTheBackupYouMayNeverBeAbleToAccessThisAccount,
                        buttonTitles: [L10n.signOut, L10n.stay],
                        highlightedButtonIndex: 1,
                        destroingIndex: 0
                    ) { [weak self] index in
                        guard index == 0 else { return }
                        self?.dismiss(animated: true, completion: { [weak self] in
                            self?.viewModel.logout()
                        })
                    }
                })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .username:
                let vc = NewUsernameViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .reserveUsername:
                guard let owner = viewModel.getUserAddress() else { return }
                let vm = ReserveName.ViewModel(
                    kind: .independent,
                    owner: owner,
                    reserveNameHandler: viewModel,
                    goBackOnCompletion: true,
                    checkBeforeReserving: true
                )
                let vc = ReserveName.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case .backup:
                let viewModel = Backup.ViewModel()
                viewModel.didBackupHandler = { [weak self] in
                    self?.viewModel.setDidBackup(true)
                }
                let vc = Backup.ViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .currency:
                let vc = SelectFiatViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .network:
                let vc = SelectNetworkViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .security:
                let vc = ConfigureSecurityViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .changePincode:
                let createPincodeVC = WLCreatePincodeVC(
                    createPincodeTitle: L10n.newPINCode,
                    confirmPincodeTitle: L10n.confirmPINCode
                )
                createPincodeVC.onSuccess = { [weak self, weak createPincodeVC] pincode in
                    self?.viewModel.savePincode(String(pincode))
                    createPincodeVC?.dismiss(animated: true) { [weak self] in
                        let vc = PinCodeChangedVC()
                        self?.present(vc, animated: true, completion: nil)
                    }
                }
                createPincodeVC.onCancel = { [weak createPincodeVC] in
                    createPincodeVC?.dismiss(animated: true, completion: nil)
                }

                // modal
                let modalVC = WLIndicatorModalVC()
                modalVC.add(child: createPincodeVC, to: modalVC.containerView)

                present(modalVC, animated: true, completion: nil)
            case .language:
                let vc = SelectLanguageViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .appearance:
                let vc = SelectAppearanceViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case let .share(item):
                let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
                present(vc, animated: true, completion: nil)
            case .accessToPhoto:
                PhotoLibraryAlertPresenter().present(on: self)
            }
        }
    }
}

private class PinCodeChangedVC: FlexibleHeightVC {
    override var padding: UIEdgeInsets { UIEdgeInsets(all: 20).modifying(dBottom: -20) }
    override var margin: UIEdgeInsets { UIEdgeInsets(all: 16).modifying(dBottom: -12) }

    init() {
        super.init(position: .center)
    }

    override func setUp() {
        super.setUp()
        stackView.addArrangedSubviews([
            UIImageView(width: 95 + 60, height: 95 + 60, image: .passcodeChanged)
                .centeredHorizontallyView,
            BEStackViewSpacing(0),
            UILabel(text: L10n.pinCodeChanged, textSize: 21, weight: .bold, numberOfLines: 0, textAlignment: .center),
            BEStackViewSpacing(30),
            WLButton.stepButton(type: .blue, label: L10n.goBackToProfile)
                .onTap(self, action: #selector(back)),
        ])
    }

    override func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let pc = super.presentationController(
            forPresented: presented,
            presenting: presenting,
            source: source
        ) as! PresentationController
        pc.roundedCorner = .allCorners
        pc.cornerRadius = 24
        return pc
    }
}
