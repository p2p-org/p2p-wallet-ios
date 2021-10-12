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
        private lazy var rootView = RootView(viewModel: viewModel)
        
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
                let vc = UsernameViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .reserveUsername(owner: let owner, handler: let handler):
                let vm = ReserveName.ViewModel(owner: owner, handler: handler)
                let vc = ReserveName.ViewController(viewModel: vm)
                vc.rootView.hideSkipButtons()
                show(vc, sender: nil)
            case .backup:
                let vc = BackupViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .backupManually:
                let vc = BackupManuallyVC()
                vc.delegate = self
                let nc = BENavigationController(rootViewController: vc)
            
                let modalVC = WLIndicatorModalVC()
                modalVC.add(child: nc, to: modalVC.containerView)
            
                present(modalVC, animated: true, completion: nil)
            case .backupShowPhrases:
                let vc = BackupShowPhrasesVC()
                present(vc, interactiveDismissalType: .standard, completion: nil)
            case .currency:
                let vc = SelectFiatViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .network:
                let vc = SelectNetworkViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .security:
                let vc = ConfigureSecurityViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .language:
                let vc = SelectLanguageViewController(viewModel: viewModel)
                show(vc, sender: nil)
            case .appearance:
                let vc = SelectAppearanceViewController(viewModel: viewModel)
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
