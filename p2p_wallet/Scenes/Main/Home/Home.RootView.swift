//
//  Home.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import UIKit
import RxSwift
import BECollectionView
import Action
import BEPureLayout

extension Home {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: HomeViewModelType
        
        // MARK: - Subviews

        private let bannersCollectionView: UICollectionView
        // swiftlint:disable weak_delegate
        private lazy var balancesScrollDelegate = BalancesScrollDelegate(balancesView: balancesOverviewView)
        private let pricesLoadingIndicatorView = WLStatusIndicatorView(forAutoLayout: ())

        private lazy var collectionView: WalletsCollectionView = {
            let collectionView = WalletsCollectionView(
                walletsRepository: viewModel.walletsRepository,
                activeWalletsSection: .init(
                    index: 0,
                    viewModel: viewModel.walletsRepository,
                    cellType: WalletCell.self
                ),
                hiddenWalletsSection: HiddenWalletsSection(
                    index: 1,
                    viewModel: viewModel.walletsRepository,
                    header: .init(viewClass: HiddenWalletsSectionHeaderView.self)
                )
            )
            collectionView.delegate = self
            collectionView.walletCellEditAction = Action<Wallet, Void> { [weak self] wallet in
                self?.viewModel.navigate(to: .walletSettings(wallet: wallet))
                return .just(())
            }
            collectionView.showHideHiddenWalletsAction = CocoaAction { [weak self] in
                self?.viewModel.walletsRepository.toggleIsHiddenWalletShown()
                return .just(())
            }
            collectionView.contentInset.modify(dTop: 10, dBottom: 50)
            return collectionView
        }()
        
        private lazy var balancesOverviewView: BalancesOverviewView = {
            let view = BalancesOverviewView()
            
            view.didTapBuy = { [weak self] in
                self?.viewModel.navigate(to: .buyToken)
            }
            view.didTapSend = { [weak self] in
                self?.viewModel.navigate(to: .sendToken(address: nil))
            }
            view.didTapReceive = { [weak self] in
                self?.viewModel.navigate(to: .receiveToken)
            }
            view.didTapSwap = {[weak self] in
                self?.viewModel.navigate(to: .swapToken)
            }
            return view
        }()

        // swiftlint:disable weak_delegate
        private let bannersDelegate: UICollectionViewDelegate
        private let bannersDataSource: BannersCollectionViewDataSource
        
        // MARK: - Initializer
        init(viewModel: HomeViewModelType) {
            self.viewModel = viewModel

            let layout = HorizontalFlowLayout(
                horisontalInset: 20,
                verticalInset: 0,
                spacing: 10
            )

            bannersCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            bannersDataSource = BannersCollectionViewDataSource(collectionView: bannersCollectionView)
            bannersDelegate = BannersCollectionViewDelegate(
                collectionView: bannersCollectionView,
                layout: layout,
                pageableScrollHandler: PageableHorizontalLayoutScrollHandler()
            )

            super.init(frame: .zero)

            configureBannersView()
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
            collectionView.scrollDelegate = balancesScrollDelegate
            collectionView.refresh()
        }

        // MARK: - Layout
        private func layout() {
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalCentering) {
                    UIImageView(width: 28, height: 28, image: .scanQr2, tintColor: .textSecondary)
                        .onTap(self, action: #selector(buttonScanQrCodeDidTouch))
                        .onSwipe(self, action: #selector(qrScannerDidSwipe(sender:)))
                    UILabel(text: L10n.p2PWallet, textSize: 17, weight: .semibold, textAlignment: .center)
                    UIImageView(width: 28, height: 28, image: .settings, tintColor: .textSecondary)
                        .onTap(self, action: #selector(buttonSettingsDidTouch))
                }
                    .padding(.init(x: 24, y: 16))
                pricesLoadingIndicatorView
                bannersCollectionView
                BEStackViewSpacing(15)
            }

            addSubview(collectionView)
            addSubview(stackView)
            addSubview(balancesOverviewView)

            stackView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            balancesOverviewView.autoPinEdge(.top, to: .bottom, of: stackView, withOffset: 8)
            balancesOverviewView.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            balancesOverviewView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)

            collectionView.autoPinEdge(.top, to: .bottom, of: stackView, withOffset: 20)
            collectionView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            let balancesViewHeight = balancesOverviewView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            collectionView.contentInset.modify(dTop: balancesViewHeight)

            bannersCollectionView.autoSetDimension(.height, toSize: 105)
        }
        
        private func bind() {
            let walletsRepository = viewModel.walletsRepository
            
            walletsRepository
                .dataObservable
                .withLatestFrom(walletsRepository.stateObservable, resultSelector: {  ($0, $1) })
                .asDriver(onErrorJustReturn: ([], .loading))
                .drive(onNext: {[weak balancesOverviewView] in
                    balancesOverviewView?.setUp(state: $1, data: $0 ?? [])
                })
                .disposed(by: disposeBag)

            viewModel.bannersDriver
                .drive(onNext: { [weak self] contents in
                    self?.bannersDataSource.bannersContent = contents
                    self?.setBannersCollectionViewIsHidden(contents.isEmpty)
                    self?.bannersCollectionView.reloadData()
                })
                .disposed(by: disposeBag)
            
            viewModel.currentPricesDriver
                .map {$0.state}
                .drive(onNext: {[weak self] state in
                    self?.configureStatusIndicatorView(state: state)
                })
                .disposed(by: disposeBag)
        }

        private func setBannersCollectionViewIsHidden(_ isHidden: Bool) {
            UIView.animate(withDuration: 0.3) {
                self.bannersCollectionView.isHidden = isHidden
            } completion: { [weak self] _ in
                self?.bannersCollectionView.alpha = isHidden ? 0: 1 // workaround: ios13
            }
        }

        private func configureBannersView() {
            bannersCollectionView.delegate = bannersDelegate
            bannersCollectionView.dataSource = bannersDataSource
            bannersCollectionView.backgroundColor = .clear

            bannersCollectionView.showsHorizontalScrollIndicator = false
        }
        
        private func configureStatusIndicatorView(state: LoadableState) {
            switch state {
            case .notRequested:
                pricesLoadingIndicatorView.isHidden = true
            case .loading:
                pricesLoadingIndicatorView.setUp(state: .loading, text: L10n.updatingPrices)
                setStatusIndicatorView(isHidden: false)
            case .loaded:
                pricesLoadingIndicatorView.setUp(state: .success, text: L10n.pricesUpdated)
                setStatusIndicatorView(isHidden: false)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                    self?.setStatusIndicatorView(isHidden: true)
                }
            case .error:
                pricesLoadingIndicatorView.setUp(state: .error, text: L10n.errorWhenUpdatingPrices)
                
                setStatusIndicatorView(isHidden: false)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                    self?.setStatusIndicatorView(isHidden: true)
                }
            }
        }
        
        private func setStatusIndicatorView(isHidden: Bool) {
            UIView.animate(withDuration: 0.3) {
                self.pricesLoadingIndicatorView.isHidden = isHidden
            }
        }
        
        // MARK: - Actions
        @objc
        private func buttonScanQrCodeDidTouch() {
            viewModel.navigate(to: .scanQr)
        }
        
        @objc
        private func buttonSettingsDidTouch() {
            viewModel.navigate(to: .settings)
        }
        
        // MARK: - Actions
        @objc
        private func qrScannerDidSwipe(sender: UIPanGestureRecognizer) {
            let translation = sender.translation(in: self)
            let progress = MenuHelper.calculateProgress(translationInView: translation, viewBounds: bounds, direction: .right
            )
            viewModel.navigateToScanQrCodeWithSwiper(progress: progress, swiperState: sender.state)
        }
    }
}

extension Home.RootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let wallet = item as? Wallet else {return}
        viewModel.navigate(to: .walletDetail(wallet: wallet))
    }
}
