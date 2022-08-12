//
//  Home.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import BECollectionView_Combine
import BEPureLayout
import Combine
import Resolver
import SolanaSwift
import UIKit

extension Home {
    class RootView: BECompositionView {
        private var subscriptions = [AnyCancellable]()
        private let viewModel: HomeViewModelType
        // swiftlint:disable weak_delegate
        private var headerViewScrollDelegate = HeaderScrollDelegate()
        // swiftlint:enable weak_delegate

        init(viewModel: HomeViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)

            viewModel.walletsRepository.reload()
        }

        override func build() -> UIView {
            BESafeArea(bottom: false) {
                BEVStack {
                    // Indicator
                    WLStatusIndicatorView(forAutoLayout: ()).setup { view in
                        viewModel.pricesLoadingStatePublisher
                            .sink { [weak view] state in
                                switch state {
                                case .notRequested:
                                    view?.isHidden = true
                                case .loading:
                                    view?.setUp(state: .loading, text: L10n.updatingPrices)
                                case .loaded:
                                    view?.setUp(state: .success, text: L10n.pricesUpdated)
                                case .error:
                                    view?.setUp(state: .error, text: L10n.errorWhenUpdatingPrices)
                                }
                            }
                            .store(in: &subscriptions)
                    }

                    BEBuilder(publisher: viewModel.isWalletEmptyPublisher) { [weak self] isEmpty in
                        guard let self = self else { return UIView() }
                        return isEmpty ? self.emptyScreen() : self.content()
                    }
                }
            }
        }

        func emptyScreen() -> UIView {
            EmptyView(viewModel: viewModel)
        }

        func content() -> UIView {
            BEZStack {
                // Tokens
                BEZStackPosition(mode: .fill) {
                    WalletsCollectionView(
                        walletsRepository: viewModel.walletsRepository,
                        sections: [
                            WalletsSection(
                                index: 0,
                                viewModel: viewModel.walletsRepository,
                                header: .init(viewClass: WalletsSection.Header.self),
                                cellType: VisibleWalletCell.self,
                                onSend: { [weak self] wallet in
                                    self?.viewModel.navigate(to: .sendToken(fromAddress: wallet.pubkey))
                                }
                            ),
                            BannerSection(index: 1, viewModel: viewModel.bannerViewModel) { [unowned self] action in
                                if let action = action as? Banners.Actions.OpenScreen {
                                    switch action.screen {
                                    case "reserve": viewModel.navigate(to: .reserveName)
                                    case "feedback": viewModel.navigate(to: .feedback)
                                    case "backup": viewModel.navigate(to: .backup)
                                    default:
                                        return
                                    }
                                }

                            },
                            HiddenWalletsSection(
                                index: 2,
                                viewModel: viewModel.walletsRepository,
                                header: .init(viewClass: HiddenWalletsSectionHeaderView.self),
                                onSend: { [weak self] wallet in
                                    self?.viewModel.navigate(to: .sendToken(fromAddress: wallet.pubkey))
                                },
                                showHideHiddenWalletsAction: { [weak self] in
                                    self?.viewModel.walletsRepository.toggleIsHiddenWalletShown()
                                }
                            ),
                        ]
                    ).setup { collectionView in
                        collectionView.delegate = self
                        collectionView.scrollDelegate = headerViewScrollDelegate

                        collectionView.contentInset.modify(dTop: 190, dBottom: 90)
                        collectionView.clipsToBounds = true

                        viewModel
                            .isWalletEmptyPublisher
                            .assign(to: \.isHidden, on: collectionView)
                            .store(in: &subscriptions)

                        viewModel
                            .scrollToTopPublisher
                            .sink { [weak collectionView] in
                                collectionView?.collectionView.setContentOffset(.init(x: 0, y: -190), animated: true)
                            }
                            .store(in: &subscriptions)
                    }
                    .padding(.init(only: .top, inset: 12))
                }

                // Action bar
                BEZStackPosition(mode: .pinEdges([.top, .left, .right])) {
                    FloatingHeaderView(viewModel: viewModel)
                        .setup { view in headerViewScrollDelegate.headerView = view }
                        .padding(.init(x: 18, y: 0))
                }
            }.padding(.init(only: .top, inset: 20))
        }
    }
}

extension Home.RootView: BECollectionViewDelegate {
    func beCollectionView(collectionView _: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let wallet = item as? Wallet else { return }
        viewModel.navigate(to: .walletDetail(wallet: wallet))
    }
}

private extension HomeViewModelType {
    var isWalletEmptyPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            walletsRepository.statePublisher,
            walletsRepository.dataPublisher
        )
            .map { state, data in
                let amount = data.reduce(0) { partialResult, wallet in partialResult + wallet.amount }
                let isEmpty = amount == 0
                return state == .loaded && isEmpty
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
