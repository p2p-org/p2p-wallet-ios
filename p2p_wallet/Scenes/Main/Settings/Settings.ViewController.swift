//
//  Settings.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import Foundation
import UIKit

extension Settings {
    class ViewController: BaseViewController {
        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var rootView = RootView()
        
        // MARK: - Initializer
        init(reserveNameHandler: ReserveNameHandler) {
            super.init()
            viewModel.set(reserveNameHandler: reserveNameHandler)
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            navigationBar.titleLabel.text = L10n.settings
            stackView.addArrangedSubview(rootView)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.logoutAlertSignal
                .emit(onNext: { [weak self] in
                    self?.showAlert(title: L10n.logout, message: L10n.doYouReallyWantToLogout, buttonTitles: ["OK", L10n.cancel], highlightedButtonIndex: 1) { [weak self] (index) in
                        guard index == 0 else {return}
                        self?.dismiss(animated: true, completion: { [weak self] in
                            self?.viewModel.logout()
                        })
                    }
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .username:
                let vc = UsernameViewController()
                show(vc, sender: nil)
            case .reserveUsername(owner: let owner, handler: let handler):
                let vm = ReserveName.ViewModel(
                    kind: .independent,
                    owner: owner,
                    reserveNameHandler: handler
                )
                let vc = ReserveName.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case .backup:
                let vc = BackupViewController()
                show(vc, sender: nil)
            case .backupManually:
                let vc = BackupManuallyVC()
                vc.delegate = self
                let nc = UINavigationController(rootViewController: vc)
            
                let modalVC = WLIndicatorModalVC()
                modalVC.add(child: nc, to: modalVC.containerView)
            
                present(modalVC, animated: true, completion: nil)
            case .backupShowPhrases:
                let vc = BackupShowPhrasesVC()
                present(vc, interactiveDismissalType: .standard, completion: nil)
            case .currency:
                let vc = SelectFiatViewController()
                show(vc, sender: nil)
            case .network:
                let vc = SelectNetworkViewController()
                show(vc, sender: nil)
            case .security:
                let vc = ConfigureSecurityViewController()
                show(vc, sender: nil)
            case .changePincode:
                let createPincodeVC = WLCreatePincodeVC(
                    createPincodeTitle: L10n.newPINCode,
                    confirmPincodeTitle: L10n.confirmPINCode
                )
                createPincodeVC.onSuccess = {[weak self, weak createPincodeVC] pincode in
                    self?.viewModel.savePincode(String(pincode))
                    createPincodeVC?.dismiss(animated: true) { [weak self] in
                        let vc = PinCodeChangedVC()
                        self?.present(vc, animated: true, completion: nil)
                    }
                }
                createPincodeVC.onCancel = {[weak createPincodeVC] in
                    createPincodeVC?.dismiss(animated: true, completion: nil)
                }
                
                // modal
                let modalVC = WLIndicatorModalVC()
                modalVC.add(child: createPincodeVC, to: modalVC.containerView)

                present(modalVC, animated: true, completion: nil)
            case .language:
                let vc = SelectLanguageViewController()
                show(vc, sender: nil)
            case .appearance:
                let vc = SelectAppearanceViewController()
                show(vc, sender: nil)
            case .share(let item):
                let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
                present(vc, animated: true, completion: nil)
            }
        }
    }
}

extension Settings.ViewController: BackupManuallyVCDelegate {
    func backupManuallyVCDidBackup(_ vc: BackupManuallyVC) {
        viewModel.setDidBackupOffline()
    }
}

private class PinCodeChangedVC: FlexibleHeightVC {
    override var padding: UIEdgeInsets { UIEdgeInsets(all: 20).modifying(dBottom: -20) }
    override var margin: UIEdgeInsets {UIEdgeInsets(all: 16).modifying(dBottom: -12)}
    init() {
        super.init(position: .center)
    }
    
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubviews([
            UIImageView(width: 95+60, height: 95+60, image: .passcodeChanged)
                .centeredHorizontallyView,
            BEStackViewSpacing(0),
            UILabel(text: L10n.pinCodeChanged, textSize: 21, weight: .bold, numberOfLines: 0, textAlignment: .center),
            BEStackViewSpacing(30),
            WLButton.stepButton(type: .blue, label: L10n.goBackToProfile)
                .onTap(self, action: #selector(back))
        ])
    }
    
    override func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = super.presentationController(forPresented: presented, presenting: presenting, source: source) as! PresentationController
        pc.roundedCorner = .allCorners
        pc.cornerRadius = 24
        return pc
    }
}
