//
//  DerivableAccountsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import BECollectionView

extension DerivableAccounts {
    class ViewController: BaseVC, DerivablePathsVCDelegate {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        // MARK: - Properties
        private let viewModel: DrivableAccountsViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Subviews
        private lazy var headerView = UIStackView(axis: .vertical, spacing: 20, alignment: .leading, distribution: .fill) {
            UIImageView(width: 36, height: 36, image: .backSquare)
                .onTap(self, action: #selector(back))
            BEStackViewSpacing(30)
            UILabel(text: L10n.derivableAccounts, textSize: 27, weight: .bold, numberOfLines: 0)
            BEStackViewSpacing(8)
            UILabel(text: L10n.ThisIsTheThingYouUseToGetAllYourAccountsFromYourMnemonicPhrase.byDefaultP2PWalletWillUseM4450100AsTheDerivationPathForTheMainWallet, textColor: .textSecondary, numberOfLines: 0)
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill) {
                derivationPathLabel
                UIImageView(width: 10, height: 8, image: .downArrow, tintColor: .a3a5ba)
            }
                .padding(.init(all: 18), backgroundColor: .grayPanel, cornerRadius: 12)
                .onTap(self, action: #selector(chooseDerivationPath))
        }
        
        private lazy var derivationPathLabel = UILabel(textSize: 17, weight: .semibold)
        private lazy var accountsCollectionView: BEStaticSectionsCollectionView = {
            let collectionView = BEStaticSectionsCollectionView(
                sections: [
                    .init(
                        index: 0,
                        layout: .init(
                            cellType: Cell.self,
                            itemHeight: .estimated(75)
                        ),
                        viewModel: viewModel.accountsListViewModel
                    )
                ]
            )
            collectionView.isUserInteractionEnabled = false
            collectionView.collectionView.contentInset.modify(dTop: 15, dBottom: 15)
            return collectionView
        }()
        
        init(viewModel: DrivableAccountsViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            analyticsManager.log(event: .recoveryDerivableAccountsOpen)
        }
        
        override func setUp() {
            super.setUp()
            view.addSubview(headerView)
            headerView.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .bottom)
            
            let separator = UIView.defaultSeparator()
            view.addSubview(separator)
            separator.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: 16)
            separator.autoPinEdge(toSuperviewEdge: .leading)
            separator.autoPinEdge(toSuperviewEdge: .trailing)
            
            view.addSubview(accountsCollectionView)
            accountsCollectionView.autoPinEdge(.top, to: .bottom, of: separator)
            accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .leading)
            accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .trailing)
            
            let separator2 = UIView.defaultSeparator()
            view.addSubview(separator2)
            separator2.autoPinEdge(.top, to: .bottom, of: accountsCollectionView)
            separator2.autoPinEdge(toSuperviewEdge: .leading)
            separator2.autoPinEdge(toSuperviewEdge: .trailing)
            
            let button = WLButton.stepButton(type: .black, label: L10n.restore)
                .onTap(self, action: #selector(restore))
            view.addSubview(button)
            button.autoPinEdge(.top, to: .bottom, of: separator2, withOffset: 16)
            button.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            button.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
            button.autoPinEdge(toSuperviewEdge: .bottom, withInset: 30)
        }
        
        override func bind() {
            super.bind()
            
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.selectedDerivablePathDriver
                .map {$0.title}
                .drive(derivationPathLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.selectedDerivablePathDriver
                .distinctUntilChanged()
                .drive(onNext: {[weak self] path in
                    self?.viewModel.accountsListViewModel.cancelRequest()
                    self?.viewModel.accountsListViewModel.setDerivablePath(path)
                    self?.viewModel.accountsListViewModel.reload()
                })
                .disposed(by: disposeBag)
        }
        
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .selectDerivationPath:
                let vc = DerivablePaths.ViewController(currentPath: viewModel.getCurrentSelectedDerivablePath())
                vc.delegate = self
                present(vc, animated: true, completion: nil)
            default:
                break
            }
        }
        
        func derivablePathsVC(_ vc: DerivablePaths.ViewController, didSelectPath path: SolanaSDK.DerivablePath) {
            viewModel.selectDerivationPath(path)
            analyticsManager.log(event: .recoveryDerivableAccountsPathSelected(path: path.rawValue))
            vc.dismiss(animated: true, completion: nil)
        }
        
        @objc func chooseDerivationPath() {
            viewModel.chooseDerivationPath()
        }
        
        @objc func restore() {
            viewModel.restoreAccount()
        }
    }
}
