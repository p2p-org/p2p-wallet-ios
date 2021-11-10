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
            collectionView.contentInset.modify(dTop: 20)
            return collectionView
        }()
        
        private lazy var balancesOverviewView: BalancesOverviewView = {
            let view = BalancesOverviewView()
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
            collectionView.refresh()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
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
                bannersCollectionView
                BEStackViewSpacing(15)
                balancesOverviewView
                    .padding(.init(x: 20, y: 0))
                
                BEStackViewSpacing(20)
                
                collectionView
            }
            addSubview(stackView)
            bannersCollectionView.autoSetDimension(.height, toSize: 105)
            stackView.autoPinEdgesToSuperviewSafeArea()
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
        }

        private func setBannersCollectionViewIsHidden(_ isHidden: Bool) {
            UIView.animate(withDuration: 0.3) {
                self.bannersCollectionView.isHidden = isHidden
            }
        }

        private func configureBannersView() {
            bannersCollectionView.delegate = bannersDelegate
            bannersCollectionView.dataSource = bannersDataSource

            bannersCollectionView.showsHorizontalScrollIndicator = false
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
