//
//  Settings.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import Combine
import Foundation
import Resolver
import SwiftUI
import UIKit

extension Settings {
    class ViewController: p2p_wallet.BaseViewController {
        var subscriptions = [AnyCancellable]()

        let viewModel: SettingsViewModelType

        init(viewModel: SettingsViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func setUp() {
            super.setUp()
            view.backgroundColor = .settingsBackground
            navigationItem.title = L10n.settings
        }

        override func build() -> UIView {
            BEVStack {
                BEScrollView(contentInsets: .init(x: 18, y: 18), spacing: 36) {
                    // Acount section
                    SectionView(title: L10n.profile) {
                        // Profile
                        if available(.onboardingUsernameEnabled) || viewModel.getUsername() != nil {
                            CellView(
                                icon: .profileIcon,
                                title: UILabel(text: L10n.username.onlyUppercaseFirst()),
                                trailing: UILabel(textSize: 15).setup { label in
                                    viewModel.usernameDriver
                                        .map { $0 != nil ? $0!.withNameServiceDomain() : L10n.notReserved }
                                        .drive(label.rx.text)
                                        .disposed(by: disposeBag)
                                    viewModel.usernameDriver.map { $0 != nil ? UIColor.textBlack : UIColor.ff3b30 }
                                        .drive(label.rx.textColor)
                                        .disposed(by: disposeBag)
                                }
                            ).onTap { [unowned self] in
                                if self.viewModel.getUsername() == nil {
                                    viewModel.showOrReserveUsername()
                                } else {
                                    viewModel.navigate(to: .username)
                                }
                            }
                        }
                        // Sign out button
                        BECenter {
                            UILabel(text: L10n.logOut, textColor: .ff3b30)
                        }
                        .frame(height: 60)
                        .onTap { [unowned self] in viewModel.showLogoutAlert() }
                    }

                    // Security & network section
                    SectionView(title: L10n.securityNetwork) {
                        // Recovery kit
                        CellView(
                            icon: .recoveryKitIcon,
                            title: UILabel(text: "Recovery kit")
                        )
                            .onTap { [unowned self] in viewModel.navigate(to: .recoveryKit) }

                        // Backup
                        CellView(
                            icon: .backupIcon,
                            title: UILabel(text: L10n.backup.onlyUppercaseFirst()),
                            trailing: UILabel(textSize: 15).setup { label in
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
                            title: UILabel().setup { view in
                                viewModel.biometryTypeDriver.map {
                                    switch $0 {
                                    case .touch: return L10n.touchID
                                    default: return L10n.faceID
                                    }
                                }.drive(view.rx.text)
                                    .disposed(by: disposeBag)
                            },
                            trailing: UISwitch().setup { switcher in
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
                        // Network
                        CellView(icon: .networkIcon, title: UILabel(text: L10n.network.onlyUppercaseFirst()))
                            .onTap { [unowned self] in viewModel.navigate(to: .network) }
                    }
                    // Appearance section
                    SectionView(title: L10n.appearance) {
                        // Currency
                        CellView(
                            icon: .currency,
                            title: UILabel(text: L10n.currency.onlyUppercaseFirst()),
                            trailing: UILabel(text: L10n.system, textColor: .secondaryLabel)
                                .setup { label in
                                    viewModel.fiatDriver
                                        .map { fiat in fiat.name }
                                        .drive(label.rx.text)
                                        .disposed(by: disposeBag)
                                }
                        ).onTap { [unowned self] in self.viewModel.navigate(to: .currency) }
                        // Hide zero balance
                        CellView(
                            icon: .hideZeroBalance,
                            title: UILabel(text: L10n.hideZeroBalances.onlyUppercaseFirst()),
                            trailing: UISwitch().setup { switcher in
                                viewModel.hideZeroBalancesDriver.drive(switcher.rx.value).disposed(by: disposeBag)
                                switcher.rx.controlEvent(.valueChanged)
                                    .withLatestFrom(switcher.rx.value)
                                    .subscribe { [unowned self] in viewModel.setHideZeroBalances($0) }
                                    .disposed(by: disposeBag)
                            },
                            nextArrowEnable: false
                        )
                    }
                    #if !RELEASE
                        SectionView(title: "Debug") {
                            CellView(
                                icon: UIImage(),
                                title: UILabel(text: "Debug Menu")
                            ).onTap { [unowned self] in
                                let view = DebugMenuView(viewModel: .init())
                                present(view.asViewController(), animated: true)
                            }
                        }
                    #endif
                    SectionView(
                        title: "\(L10n.appVersion): \(viewModel.appVersion)\(Environment.current != .release ? ("(" + Bundle.main.buildVersionNumber + ")" + " " + Environment.current.description) : "")"
                    ) {}
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
                        title: L10n.doYouWantToLogOut,
                        message: L10n.youWillNeedYourSocialAccountOrPhoneNumberToLogIn,
                        buttonTitles: [L10n.logOut, L10n.stay],
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
                guard let navigationController = navigationController else { return }
                CreateUsernameCoordinator(navigationOption: .settings(parent: navigationController))
                    .start()
                    .sink { navigationController.popToViewController(ofClass: ViewController.self, animated: true) }
                    .store(in: &subscriptions)
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
                guard let navigationController = navigationController else { return }
                let pincodeChangeCoordinator = PincodeChangeCoordinator(navVC: navigationController)
                pincodeChangeCoordinator
                    .start()
                    .sink { _ in
                        navigationController.popToViewController(ofClass: ViewController.self, animated: true)
                    }
                    .store(in: &subscriptions)

            // let createPincodeVC = WLCreatePincodeVC(
            //     createPincodeTitle: L10n.setUpANewWalletPIN,
            //     confirmPincodeTitle: L10n.confirmPINCode
            // )
            //
            // createPincodeVC.onSuccess = { [weak self, weak createPincodeVC] pincode in
            //     self?.viewModel.savePincode(String(pincode))
            //     createPincodeVC?.dismiss(animated: true) {
            //         Resolver.resolve(NotificationService.self)
            //             .showInAppNotification(.done(L10n.youHaveSuccessfullySetYourPIN))
            //     }
            // }
            // createPincodeVC.onCancel = { [weak createPincodeVC] in
            //     createPincodeVC?.dismiss(animated: true, completion: nil)
            // }
            //
            // present(createPincodeVC, animated: true, completion: nil)
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
            case .recoveryKit:
                guard let navigationController = navigationController else { return }
                RecoveryKitCoordinator(navigationController: navigationController)
                    .start()
                    .sinkAsync {}
                    .store(in: &subscriptions)
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

private extension Environment {
    var description: String {
        switch self {
        case .debug:
            return "Debug"
        case .test:
            return "Test"
        case .release:
            return "Release"
        }
    }
}
