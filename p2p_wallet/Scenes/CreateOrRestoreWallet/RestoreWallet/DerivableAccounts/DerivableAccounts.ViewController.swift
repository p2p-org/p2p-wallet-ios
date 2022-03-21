//
//  DerivableAccountsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import BECollectionView
import Foundation

extension DerivableAccounts {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Properties

        private let viewModel: DrivableAccountsViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType

        // MARK: - Subviews

        lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backgroundColor = .clear
            navigationBar.titleLabel.text = L10n.derivableAccounts
            return navigationBar
        }()

        private lazy var headerView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
            WLCard {
                UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill) {
                    UIStackView(axis: .vertical, spacing: 8, alignment: .leading) {
                        UILabel(text: L10n.derivationPath, textSize: 17, weight: .semibold)
                        derivationPathLabel
                    }
                    UIView.defaultNextArrow()
                }.padding(.init(x: 18, y: 14))
            }.onTap(self, action: #selector(chooseDerivationPath))

            UIView.greyBannerView {
                UILabel(text: L10n.ThisIsTheThingYouUseToGetAllYourAccountsFromYourMnemonicPhrase.byDefaultP2PWalletWillUseM4450100AsTheDerivationPathForTheMainWallet, numberOfLines: 0)
            }
        }

        private lazy var derivationPathLabel = UILabel(textSize: 13, weight: .regular, textColor: .h8e8e93)
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
                    ),
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

            // navigation bar
            view.addSubview(navigationBar)
            navigationBar.backButton.onTap(self, action: #selector(back))
            navigationBar.autoPinEdge(toSuperviewSafeArea: .top)
            navigationBar.autoPinEdge(toSuperviewEdge: .leading)
            navigationBar.autoPinEdge(toSuperviewEdge: .trailing)

            view.addSubview(headerView)
            headerView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 4)
            headerView.autoPinEdge(toSuperviewEdge: .left, withInset: 20)
            headerView.autoPinEdge(toSuperviewEdge: .right, withInset: 20)

            view.addSubview(accountsCollectionView)
            accountsCollectionView.autoPinEdge(.top, to: .bottom, of: headerView)
            accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .leading)
            accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .trailing)

            let button = WLButton.stepButton(type: .blue, label: L10n.continue)
                .onTap(self, action: #selector(restore))
            view.addSubview(button)
            button.autoPinEdge(.top, to: .bottom, of: accountsCollectionView, withOffset: 16)
            button.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            button.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
            button.autoPinEdge(toSuperviewEdge: .bottom, withInset: 30)
        }

        override func bind() {
            super.bind()

            viewModel.navigatableSceneDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)

            viewModel.selectedDerivablePathDriver
                .map { $0.title }
                .drive(derivationPathLabel.rx.text)
                .disposed(by: disposeBag)

            viewModel.selectedDerivablePathDriver
                .distinctUntilChanged()
                .drive(onNext: { [weak self] path in
                    self?.viewModel.accountsListViewModel.cancelRequest()
                    self?.viewModel.accountsListViewModel.setDerivablePath(path)
                    self?.viewModel.accountsListViewModel.reload()
                })
                .disposed(by: disposeBag)
        }

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .selectDerivationPath:
                let vc = DerivablePaths.ViewController(currentPath: viewModel.getCurrentSelectedDerivablePath()) { [weak self] path in
                    self?.derivablePathsVC(didSelectPath: path)
                }
                present(vc, animated: true, completion: nil)
            default:
                break
            }
        }

        func derivablePathsVC(didSelectPath path: SolanaSDK.DerivablePath) {
            viewModel.selectDerivationPath(path)
            analyticsManager.log(event: .recoveryDerivableAccountsPathSelected(path: path.rawValue))
        }

        @objc func chooseDerivationPath() {
            viewModel.chooseDerivationPath()
        }

        @objc func restore() {
            viewModel.restoreAccount()
        }
    }
}
