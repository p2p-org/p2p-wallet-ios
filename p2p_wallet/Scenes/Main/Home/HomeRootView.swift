//
//  HomeRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import UIKit
import Action
import BECollectionView
import RxSwift

class HomeRootView: BEView {
    // MARK: - Constants
    private let disposeBag = DisposeBag()
    
    // MARK: - Properties
    let viewModel: HomeViewModel
    var headerViewTopConstraint: NSLayoutConstraint!
    
    // MARK: - Subviews
    lazy var headerView: UIView = {
        let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing) {
            UIImageView(width: 45, height: 45, image: .scanQr, tintColor: .textSecondary
            )
                .onTap(self, action: #selector(qrScannerDidTouch))
                .onSwipe(self, action: #selector(qrScannerDidSwipe(sender:)))
            
            UIImageView(width: 25, height: 25, image: .settings, tintColor: .textSecondary)
                .onTap(viewModel, action: #selector(HomeViewModel.showSettings))
        }
        
        let view = UIView(backgroundColor: .white.onDarkMode(.h1b1b1b))
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(top: 10, left: 16, bottom: 6, right: 20))
        return view
    }()
    
    lazy var collectionView: HomeCollectionView = {
        let collectionView = HomeCollectionView(walletsRepository: viewModel.walletsRepository)
        collectionView.delegate = self

        collectionView.walletCellEditAction = Action<Wallet, Void> { [weak self] wallet in
            self?.viewModel.navigationSubject.onNext(.walletSettings(wallet: wallet))
            return .just(())
        }
        collectionView.showHideHiddenWalletsAction = CocoaAction { [weak self] in
            self?.viewModel.walletsRepository.toggleIsHiddenWalletShown()
            return .just(())
        }
        return collectionView
    }()
    
    lazy var tabBar: TabBar = {
        let tabBar = TabBar(
            shadowColor: BEPureLayoutConfigs.defaultShadowColor.onDarkMode(.clear), // temporarily disable shadow
            cornerRadius: .defaultPadding,
            contentInset: UIEdgeInsets(top: 20, left: 0, bottom: 8, right: 0)
        )
        tabBar.backgroundColor = .white.onDarkMode(.h2a2a2a)
        tabBar.stackView.addArrangedSubviews([
            .spacer,
//                    createButton(image: .walletAdd, title: L10n.buy),
            createButton(image: .walletReceive, title: L10n.receive)
                .onTap(viewModel, action: #selector(HomeViewModel.receiveToken)),
            createButton(image: .walletSend, title: L10n.send)
                .onTap(viewModel, action: #selector(HomeViewModel.sendToken)),
            createButton(image: .walletSwap, title: L10n.swap)
                .onTap(viewModel, action: #selector(HomeViewModel.swapToken)),
            .spacer
        ])
        return tabBar
    }()
    
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
        // collection view
        addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
        
        // header view
        addSubview(headerView)
        headerViewTopConstraint = headerView.autoPinEdge(toSuperviewSafeArea: .top)
        headerView.autoPinEdge(toSuperviewEdge: .leading)
        headerView.autoPinEdge(toSuperviewEdge: .trailing)
        
        // tabbar
        addSubview(tabBar)
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
        // collectionView modifier
        collectionView.collectionView.contentInset = .init(top: 50 + safeAreaInsets.top, left: 0, bottom: 120, right: 0)
    }
    
    private func bind() {
        let stateDriver = viewModel.walletsRepository
            .stateObservable
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .initializing)
        
        stateDriver
            .map {$0 == .loading}
            .drive(onNext: {[weak self] isLoading in
                if isLoading {
                    self?.showLoadingIndicatorView()
                } else {
                    self?.hideLoadingIndicatorView()
                }
            })
            .disposed(by: disposeBag)
        
        stateDriver
            .map {$0 == .error}
            .drive(onNext: {[weak self] hasError in
                if hasError, self?.viewModel.walletsRepository.getError()?.asAFError != nil
                {
                    self?.showConnectionErrorView(refreshAction: CocoaAction { [weak self] in
                        self?.viewModel.walletsRepository.reload()
                        return .just(())
                    })
                } else {
                    self?.hideConnectionErrorView()
                }
            })
            .disposed(by: disposeBag)
        
        collectionView.collectionView.rx.willEndDragging
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.toggleHeaderViewVisibility()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func createButton(image: UIImage, title: String) -> UIStackView {
        let button = UIButton(width: 56, height: 56, backgroundColor: .h5887ff, cornerRadius: 12, label: title, contentInsets: .init(all: 16))
        button.setImage(image, for: .normal)
        button.isUserInteractionEnabled = false
        button.tintColor = .white
        return UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill, arrangedSubviews: [
            button,
            UILabel(text: title, textSize: 12, textColor: .textSecondary)
        ])
    }
    
    private func toggleHeaderViewVisibility() {
        let translation = collectionView.collectionView.panGestureRecognizer.translation(in: collectionView)
        
        var constant = headerViewTopConstraint.constant
        
        if translation.y < 0 {
            // hide header view
            constant = -100
        } else {
            // show header view
            constant = 0
        }
        
        if constant != headerViewTopConstraint.constant {
            headerViewTopConstraint.constant = constant
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Actions
    @objc func qrScannerDidSwipe(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        let progress = MenuHelper.calculateProgress(translationInView: translation, viewBounds: bounds, direction: .right
        )
        viewModel.navigationSubject.onNext(.scanQrWithSwiper(progress: progress, state: sender.state))
    }
    
    @objc func qrScannerDidTouch() {
        viewModel.navigationSubject.onNext(.scanQrCodeWithTap)
    }
}

extension HomeRootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionView, didSelect item: AnyHashable) {
        guard let wallet = item as? Wallet else {return}
        viewModel.navigationSubject.onNext(.walletDetail(wallet: wallet))
    }
}
