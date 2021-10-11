//
//  HomeViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import UIKit
import Action
import RxCocoa

protocol HomeScenesFactory {
    func makeWalletDetailViewController(pubkey: String, symbol: String) -> WalletDetail.ViewController
    func makeBuyTokenViewController(token: BuyToken.CryptoCurrency) throws -> UIViewController
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.ViewController?
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController
    func makeSwapTokenViewController(provider: SwapProvider, fromWallet wallet: Wallet?) -> CustomPresentableViewController
    func makeMyProductsViewController() -> MyProductsViewController
    func makeProfileVC(reserveNameHandler: ReserveNameHandler) -> ProfileVC
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
}

class HomeViewController: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    // MARK: - Properties
    let viewModel: HomeViewModel
    let scenesFactory: HomeScenesFactory
    @Injected private var analyticsManager: AnalyticsManagerType
    
    // MARK: - Initializer
    init(viewModel: HomeViewModel, scenesFactory: HomeScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func loadView() {
        view = HomeRootView(viewModel: viewModel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsManager.log(event: .mainScreenWalletsOpen)
    }
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func bind() {
        super.bind()
        
        let stateDriver = viewModel.walletsRepository
            .stateObservable
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .initializing)
        
        stateDriver
            .map {$0 == .loading}
            .drive(onNext: {[weak self] isLoading in
                if isLoading {
                    self?.view.showLoadingIndicatorView()
                } else {
                    self?.view.hideLoadingIndicatorView()
                }
            })
            .disposed(by: disposeBag)
        
        stateDriver
            .map {$0 == .error}
            .drive(onNext: {[weak self] hasError in
                if hasError, self?.viewModel.walletsRepository.getError()?.asAFError != nil
                {
                    self?.view.showConnectionErrorView(refreshAction: CocoaAction { [weak self] in
                        self?.viewModel.walletsRepository.reload()
                        return .just(())
                    })
                } else {
                    self?.view.hideConnectionErrorView()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.navigationDriver
            .drive(onNext: {[weak self] in self?.navigate(to: $0)})
            .disposed(by: disposeBag)
        
        viewModel.nameDidReserveSignal
            .emit(onNext: { [weak self] in
                if self?.navigationController?.viewControllers.last is ReserveName.ViewController {
                    self?.navigationController?.popViewController(animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: HomeNavigatableScene) {
        switch scene {
        case .buyToken:
            do {
                let vc = try scenesFactory.makeBuyTokenViewController(token: .all)
                analyticsManager.log(event: .mainScreenBuyOpen)
                present(vc, animated: true, completion: nil)
            } catch {
                showAlert(title: L10n.error, message: error.readableDescription)
            }
        case .receiveToken:
            if let vc = scenesFactory.makeReceiveTokenViewController(tokenWalletPubkey: nil)
            {
                analyticsManager.log(event: .mainScreenReceiveOpen)
                analyticsManager.log(event: .receiveOpen(fromPage: "main_screen"))
                present(vc, interactiveDismissalType: .standard, completion: nil)
            }
        case .scanQr:
            analyticsManager.log(event: .mainScreenQrOpen)
            analyticsManager.log(event: .scanQrOpen(fromPage: "main_screen"))
        case .sendToken(let address):
            let vc = scenesFactory
                .makeSendTokenViewController(walletPubkey: nil, destinationAddress: address)
            analyticsManager.log(event: .mainScreenSendOpen)
            analyticsManager.log(event: .sendOpen(fromPage: "main_screen"))
            present(vc, interactiveDismissalType: .standard, completion: nil)
        case .swapToken:
            let vc = scenesFactory.makeSwapTokenViewController(provider: .orca, fromWallet: nil)
            analyticsManager.log(event: .mainScreenSwapOpen)
            analyticsManager.log(event: .swapOpen(fromPage: "main_screen"))
            present(vc, interactiveDismissalType: .standard, completion: nil)
        case .allProducts:
            let vc = scenesFactory.makeMyProductsViewController()
            self.present(vc, animated: true, completion: nil)
        case .profile:
            analyticsManager.log(event: .mainScreenSettingsOpen)
            analyticsManager.log(event: .settingsOpen(fromPage: "main_screen"))
            let profileVC = scenesFactory.makeProfileVC(reserveNameHandler: viewModel)
            self.show(profileVC, sender: nil)
        case .reserveName(let owner):
            let vm = ReserveName.ViewModel(owner: owner, handler: viewModel)
            let vc = CustomReserveNameVC(viewModel: vm)
            self.present(vc, interactiveDismissalType: .standard)
            
            viewModel.nameDidReserveSignal
                .emit(onNext: { [weak vc] in
                    vc?.back()
                })
                .disposed(by: disposeBag)
        case .walletDetail(let wallet):
            guard let pubkey = wallet.pubkey else {return}
            
            analyticsManager.log(event: .mainScreenTokenDetailsOpen(tokenTicker: wallet.token.symbol))
            
            let vc = scenesFactory.makeWalletDetailViewController(pubkey: pubkey, symbol: wallet.token.symbol)
            present(vc, interactiveDismissalType: .standard)
        case .walletSettings(let wallet):
            guard let pubkey = wallet.pubkey else {return}
            let vc = scenesFactory.makeTokenSettingsViewController(pubkey: pubkey)
            self.present(vc, animated: true, completion: nil)
        }
    }
}

private class CustomReserveNameVC: WLIndicatorModalVC, CustomPresentableViewController {
    var transitionManager: UIViewControllerTransitioningDelegate?
    
    // MARK: - Dependencies
    private var viewModel: ReserveNameViewModelType
    
    private lazy var headerView: UIView = {
        let view = UIView(forAutoLayout: ())
        let label = UILabel(text: L10n.reserveYourP2PUsername, textSize: 17, weight: .semibold)
        view.addSubview(label)
        label.autoPinEdgesToSuperviewEdges(with: .init(all: 20))
        let separator = UIView.defaultSeparator()
        view.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        return view
    }()
    private lazy var childReserveNameVC = ReserveName.ViewController(viewModel: viewModel)
    
    // MARK: - Initializer
    init(viewModel: ReserveNameViewModelType) {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        // add header
        containerView.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        // add childReserveNameVC to container
        let childContainerView = UIView(forAutoLayout: ())
        containerView.addSubview(childContainerView)
        childContainerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        childContainerView.autoPinEdge(.top, to: .bottom, of: headerView)
        
        // add child vc
        add(child: childReserveNameVC, to: childContainerView)
        
        // relayout ReserveNameVC (replace header)
        childReserveNameVC.view.subviews.forEach {$0.removeFromSuperview()}
        childReserveNameVC.view.addSubview(childReserveNameVC.rootView)
        childReserveNameVC.rootView.autoPinEdgesToSuperviewEdges()
    }
    
    override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        super.calculateFittingHeightForPresentedView(targetWidth: targetWidth)
            + headerView.fittingHeight(targetWidth: targetWidth)
            + childReserveNameVC.rootView.fittingHeight(targetWidth: targetWidth)
    }
}
