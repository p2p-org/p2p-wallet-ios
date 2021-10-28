//
//  HomeRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import UIKit
import Action
import BECollectionView
import BEPureLayout
import RxSwift

class HomeRootView: BEView {
    // MARK: - Constants
    let disposeBag = DisposeBag()
    
    // MARK: - Properties
    private let viewModel: HomeViewModel
    
    // MARK: - Subviews
    private lazy var collectionView: WalletsCollectionView = {
        let collectionView = WalletsCollectionView(
            walletsRepository: viewModel.walletsRepository,
            activeWalletsSection: .init(
                index: 0,
                viewModel: viewModel.walletsRepository,
                cellType: HomeWalletCell.self
            ),
            hiddenWalletsSection: HiddenWalletsSection(
                index: 1,
                viewModel: viewModel.walletsRepository,
                header: .init(viewClass: HiddenWalletsSectionHeaderView.self)
            )
        )
        collectionView.delegate = self
        collectionView.walletCellEditAction = viewModel.navigateToWalletSettingsAction()
        collectionView.showHideHiddenWalletsAction = viewModel.showHideHiddenWalletAction()
        collectionView.contentInset.modify(dTop: 20)
        return collectionView
    }()
    
    private lazy var balancesOverviewView = BalancesOverviewView()
    
    // MARK: - Initializers
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        layout()
        bind()
        collectionView.refresh()
        
    }
    
    // MARK: - Layout
    private func layout() {
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalCentering) {
                UIImageView(width: 28, height: 28, image: .scanQr2, tintColor: .textSecondary)
                    .onTap(self, action: #selector(buttonScanQrCodeDidTouch))
                UILabel(text: L10n.p2PWallet, textSize: 17, weight: .semibold, textAlignment: .center)
                UIImageView(width: 28, height: 28, image: .settings, tintColor: .textSecondary)
                    .onTap(self, action: #selector(buttonSettingsDidTouch))
            }
                .padding(.init(x: 24, y: 16))
            
            balancesOverviewView
                .padding(.init(x: 20, y: 0))
            
            BEStackViewSpacing(20)
            
            collectionView
        }
        addSubview(stackView)
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
    }
    
    // MARK: - Actions
    @objc
    private func buttonScanQrCodeDidTouch() {
        viewModel.navigationSubject.onNext(.scanQr)
    }
    
    @objc
    private func buttonSettingsDidTouch() {
        viewModel.navigationSubject.onNext(.settings)
    }
}

extension HomeRootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let wallet = item as? Wallet else {return}
        viewModel.showWalletDetail(wallet: wallet)
    }
}
