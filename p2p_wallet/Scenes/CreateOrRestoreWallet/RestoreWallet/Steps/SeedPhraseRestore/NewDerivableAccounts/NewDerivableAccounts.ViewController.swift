import AnalyticsManager
import BECollectionView_Combine
import Combine
import Foundation
import KeyAppUI
import Resolver
import SolanaSwift

extension NewDerivableAccounts {
    class ViewController: BaseVC {
        // MARK: - Properties

        private let viewModel: NewDrivableAccountsViewModelType
        @Injected private var analyticsManager: AnalyticsManager
        private var subscriptions = [AnyCancellable]()
        var continueButton: TextButton?

        // MARK: - Subviews

        private lazy var headerView = UIStackView(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill) {
            WLCard(cornerRadius: 16) {
                UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill) {
                    UIStackView(axis: .vertical, spacing: 4, alignment: .leading) {
                        UILabel(text: L10n.derivationPath, textSize: 16, weight: .regular)
                        derivationPathLabel
                    }
                    UIImageView(
                        width: 20,
                        height: 25,
                        image: Asset.MaterialIcon.chevronRight.image,
                        tintColor: Asset.Colors.mountain.color
                    ).setup { image in
                        image.contentMode = .scaleAspectFill
                    }
                    .padding(.init(only: .right, inset: 3))
                }.padding(.init(x: 29, y: 14))
            }.onTap(self, action: #selector(chooseDerivationPath))

            UIView.greyBannerView {
                UILabel(
                    text: L10n.ThisIsTheThingYouUseToGetAllYourAccountsFromYourMnemonicPhrase
                        .byDefaultP2PWalletWillUseM4450100AsTheDerivationPathForTheMainWallet,
                    numberOfLines: 0
                )
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
                        viewModel: viewModel.accountsListViewModel as! BECollectionViewModelType
                    ),
                ]
            )
            collectionView.isUserInteractionEnabled = false
            collectionView.collectionView.contentInset.modify(dTop: 15, dBottom: 15)
            return collectionView
        }()

        init(viewModel: NewDrivableAccountsViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            analyticsManager.log(event: AmplitudeEvent.recoveryDerivableAccountsOpen)
        }

        override func setUp() {
            super.setUp()

            // navigation bar
            configureNavBar()

            view.addSubview(headerView)
            headerView.autoPinEdge(toSuperviewSafeArea: .top, withInset: 12)
            headerView.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            headerView.autoPinEdge(toSuperviewEdge: .right, withInset: 16)

            view.addSubview(accountsCollectionView)
            accountsCollectionView.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: 16)
            accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .leading)
            accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .trailing)

            let button = TextButton(
                title: L10n.continue,
                style: .primary,
                size: .large,
                trailing: Asset.MaterialIcon.arrowForward.image
            ).onPressed { _ in self.restore() }
            view.addSubview(button)
            continueButton = button

            button.autoPinEdge(.top, to: .bottom, of: accountsCollectionView, withOffset: 16)
            button.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            button.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
            button.autoPinEdge(toSuperviewEdge: .bottom, withInset: 44)
        }

        override func bind() {
            super.bind()

            viewModel.navigatableScenePublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)

            viewModel.selectedDerivablePathPublisher
                .map(\.title)
                .map { Optional($0) }
                .assign(to: \.text, on: derivationPathLabel)
                .store(in: &subscriptions)

            viewModel.selectedDerivablePathPublisher
                .removeDuplicates()
                .sink { [weak self] path in
                    self?.viewModel.accountsListViewModel.cancelRequest()
                    self?.viewModel.accountsListViewModel.setDerivablePath(path)
                    self?.viewModel.accountsListViewModel.reload()
                }
                .store(in: &subscriptions)

            viewModel.loadingPublisher.removeDuplicates().sink { loading in
                self.continueButton?.isLoading = loading
            }.store(in: &subscriptions)
        }

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .selectDerivationPath:
                let vc = NewDerivablePaths
                    .ViewController(currentPath: viewModel.getCurrentSelectedDerivablePath()) { [weak self] path in
                        self?.derivablePathsVC(didSelectPath: path)
                    }
                present(vc, animated: true)
            default:
                break
            }
        }

        func derivablePathsVC(didSelectPath path: DerivablePath) {
            viewModel.selectDerivationPath(path)
            analyticsManager.log(event: AmplitudeEvent.recoveryDerivableAccountsPathSelected(path: path.rawValue))
        }

        @objc func chooseDerivationPath() {
            viewModel.chooseDerivationPath()
        }

        @objc func restore() {
            viewModel.restoreAccount()
        }

        @objc func onBack() {
            viewModel.onBack()
        }

        func configureNavBar() {
            navigationItem.title = L10n.derivableAccounts
            // Left button
            let backButton = UIBarButtonItem(
                image: Asset.MaterialIcon.arrowBackIos.image,
                style: .plain,
                target: self,
                action: #selector(onBack)
            )
            backButton.tintColor = Asset.Colors.night.color

            let spacing = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            spacing.width = 8

            navigationItem.setLeftBarButtonItems([spacing, backButton], animated: false)
        }
    }
}
