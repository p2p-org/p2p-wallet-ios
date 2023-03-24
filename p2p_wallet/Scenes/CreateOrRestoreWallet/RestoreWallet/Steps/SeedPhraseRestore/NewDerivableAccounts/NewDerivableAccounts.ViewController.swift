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
                        derivablePathLabel
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
            }.onTap(self, action: #selector(navigateToSelectDerivableType))

            UIView.greyBannerView {
                UILabel(
                    text: L10n.ThisIsTheThingYouUseToGetAllYourAccountsFromYourMnemonicPhrase
                        .byDefaultKeyAppWillUseM4450100AsTheDerivationPathForTheMainWallet,
                    numberOfLines: 0
                )
            }
        }

        private lazy var derivablePathLabel = UILabel(textSize: 13, weight: .regular, textColor: .h8e8e93)
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
            collectionView.collectionView.contentInset.modify(dTop: 15, dBottom: 15)
            return collectionView
        }()

        init(viewModel: NewDrivableAccountsViewModelType) {
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
            configureNavBar()

            view.addSubview(headerView)
            headerView.autoPinEdge(toSuperviewSafeArea: .top, withInset: 12)
            headerView.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            headerView.autoPinEdge(toSuperviewEdge: .right, withInset: 16)

            view.addSubview(accountsCollectionView)
            accountsCollectionView.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: 16)
            accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .leading)
            accountsCollectionView.autoPinEdge(toSuperviewSafeArea: .trailing)
            accountsCollectionView.autoPinEdge(toSuperviewEdge: .bottom)
            
            accountsCollectionView.contentInset.modify(dBottom: 44)
            
            accountsCollectionView.delegate = self
        }

        override func bind() {
            super.bind()

            viewModel.navigatableScenePublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)

            viewModel.selectedDerivablePathPublisher
                .map(\.title)
                .map { Optional($0) }
                .assign(to: \.text, on: derivablePathLabel)
                .store(in: &subscriptions)

            viewModel.loadingPublisher.removeDuplicates().sink { loading in
                self.continueButton?.isLoading = loading
            }.store(in: &subscriptions)
        }

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .selectDerivableType:
                let vc = SelectDerivableType
                    .ViewController(
                        currentType: viewModel.getCurrentSelectedDerivablePath().type
                    ) { [weak self] type in
                        self?.selectDerivableTypeVC(didSelectType: type)
                    }
                present(vc, animated: true)
            default:
                break
            }
        }

        func selectDerivableTypeVC(didSelectType derivableType: DerivablePath.DerivableType) {
            viewModel.selectDerivableType(derivableType)
            analyticsManager.log(event: .recoveryDerivableAccountsPathSelected(path: DerivablePath(type: derivableType, walletIndex: 0).rawValue))
        }

        @objc func navigateToSelectDerivableType() {
            viewModel.navigateToSelectDerivableType()
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

extension NewDerivableAccounts.ViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let item = item as? DerivableAccount else { return }
        viewModel.selectDerivablePath(item.derivablePath)
    }
}
