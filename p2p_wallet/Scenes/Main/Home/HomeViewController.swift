//
//  HomeViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import UIKit

protocol HomeScenesFactory {
    func makeWalletDetailViewController(pubkey: String, symbol: String) -> WalletDetailViewController
    func makeReceiveTokenViewController(pubkey: String?) -> ReceiveTokenViewController
    func makeSendTokenViewController(activeWallet: Wallet?, destinationAddress: String?) -> SendTokenViewController
    func makeSwapTokenViewController(fromWallet wallet: Wallet?) -> SwapTokenViewController
    func makeMyProductsViewController() -> MyProductsViewController
    func makeProfileVC() -> ProfileVC
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
    func makeAddNewTokenVC() -> AddNewWalletVC
}

class HomeViewController: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    // MARK: - Properties
    let viewModel: HomeViewModel
    let scenesFactory: HomeScenesFactory
    let interactor = MenuInteractor()
    
    // MARK: - Tabbar
    lazy var avatarImageView = UIImageView(width: 30, height: 30, image: .settings, tintColor: .textSecondary)
        .onTap(viewModel, action: #selector(HomeViewModel.showSettings))
    lazy var homeRootView = HomeRootView(viewModel: viewModel)
    lazy var tabBar: TabBar = {
        let tabBar = TabBar(cornerRadius: .defaultPadding, contentInset: UIEdgeInsets(top: 20, left: 0, bottom: 8, right: 0))
        tabBar.backgroundColor = .background2
        tabBar.alpha = 0
        return tabBar
    }()
    
    // MARK: - Initializer
    init(viewModel: HomeViewModel, scenesFactory: HomeScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
        setStatusBarColor(view.backgroundColor!)
        
        let headerView = UIView(forAutoLayout: ())
        headerView.row([
            {
                let qrScannerView = UIImageView(width: 25, height: 25, image: .scanQr, tintColor: .textSecondary
                )
                    .onTap(self, action: #selector(qrScannerDidTouch))
                qrScannerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(qrScannerDidSwipe(sender:))))
                return qrScannerView
            }(),
            avatarImageView
        ], padding: .init(x: .defaultPadding, y: 10))
        view.addSubview(headerView)
        headerView.autoPinEdge(toSuperviewEdge: .leading)
        headerView.autoPinEdge(toSuperviewEdge: .trailing)
        headerView.autoPinEdge(toSuperviewSafeArea: .top)
        
        view.addSubview(homeRootView)
        homeRootView.autoPinEdge(.top, to: .bottom, of: headerView)
        homeRootView.autoPinEdge(toSuperviewEdge: .leading)
        homeRootView.autoPinEdge(toSuperviewEdge: .trailing)
        
        // tabBar
        view.addSubview(tabBar)
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        tabBar.autoPinEdge(.top, to: .bottom, of: homeRootView)
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
        
        // delegate
        homeRootView.collectionView.delegate = self
    }
    
    override func bind() {
        super.bind()
        viewModel.walletsVM
            .state
            .map {$0 == .loading}
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: {[weak self] isLoading in
                if isLoading {
                    self?.view.showLoadingIndicatorView(presentationStyle: .fullScreen)
                } else {
                    self?.view.hideLoadingIndicatorView()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.navigationSubject
            .subscribe(onNext: {[unowned self] in self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: HomeNavigatableScene) {
        switch scene {
        case .receiveToken:
            let vc = self.scenesFactory.makeReceiveTokenViewController(pubkey: nil)
            self.present(vc, animated: true, completion: nil)
        case .scanQr:
            break
        case .sendToken(let address):
            let vc = self.scenesFactory
                .makeSendTokenViewController(activeWallet: nil, destinationAddress: address)
            self.present(vc, animated: true, completion: nil)
        case .swapToken:
            let vc = self.scenesFactory.makeSwapTokenViewController(fromWallet: nil)
            self.present(vc, animated: true, completion: nil)
        case .allProducts:
            let vc = self.scenesFactory.makeMyProductsViewController()
            self.present(vc, animated: true, completion: nil)
        case .profile:
            let profileVC = self.scenesFactory.makeProfileVC()
            self.show(profileVC, sender: nil)
        case .walletDetail(let wallet):
            guard let pubkey = wallet.pubkey else {return}
            let vc = scenesFactory.makeWalletDetailViewController(pubkey: pubkey, symbol: wallet.symbol)
            present(vc, animated: true, completion: nil)
        case .walletSettings(let wallet):
            guard let pubkey = wallet.pubkey else {return}
            let vc = self.scenesFactory.makeTokenSettingsViewController(pubkey: pubkey)
            self.present(vc, animated: true, completion: nil)
        case .addToken:
            let vc = self.scenesFactory.makeAddNewTokenVC()
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func qrScannerDidSwipe(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let progress = MenuHelper.calculateProgress(translationInView: translation, viewBounds: view.bounds, direction: .right
        )
        MenuHelper.mapGestureStateToInteractor(
            gestureState: sender.state,
            progress: progress,
            interactor: interactor)
        {
            let vc = QrCodeScannerVC()
            vc.callback = { code in
                if NSRegularExpression.publicKey.matches(code) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.viewModel.navigationSubject.onNext(.sendToken(address: code))
                    }
                    return true
                }
                return false
            }
            vc.transitioningDelegate = self
            vc.modalPresentationStyle = .custom
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func qrScannerDidTouch() {
        let vc = QrCodeScannerVC()
        vc.callback = { code in
            if NSRegularExpression.publicKey.matches(code) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.viewModel.navigationSubject.onNext(.sendToken(address: code))
                }
                return true
            }
            return false
        }
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
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
}

extension HomeViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        PresentMenuAnimator()
    }
    
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        DismissMenuAnimator()
//    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}

extension HomeViewController: CollectionViewDelegate {
    func dataDidLoad() {
        UIView.animate(withDuration: 0.3) {
            self.tabBar.alpha = self.viewModel.homeCollectionViewModel.walletsVM.data.isEmpty ? 0 : 1
        }
    }
}
