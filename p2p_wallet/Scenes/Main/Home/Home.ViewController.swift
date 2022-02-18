//
//  Home.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import Foundation
import UIKit
import Action
import RxCocoa

extension Home {
    class ViewController: BaseVC, TabBarNeededViewController {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var analyticsManager: AnalyticsManagerType
        private let viewModel: HomeViewModelType
        
        // MARK: - Properties
        fileprivate let interactor = MenuInteractor()
        
        // MARK: - Initializer
        init(viewModel: HomeViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func loadView() {
            view = RootView(viewModel: viewModel)
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            analyticsManager.log(event: .mainScreenWalletsOpen)
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
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .buyToken:
                let vm = BuyRoot.ViewModel()
                let vc = BuyRoot.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case .receiveToken:
                if let pubkey = try? SolanaSDK.PublicKey(string: viewModel.walletsRepository.nativeWallet?.pubkey) {
                    let isDevnet = Defaults.apiEndPoint.network == .devnet
                    let renBTCMint: SolanaSDK.PublicKey = isDevnet ? .renBTCMintDevnet : .renBTCMint
                    
                    let isRenBTCWalletCreated = viewModel.walletsRepository.getWallets().contains(where: {
                        $0.token.address == renBTCMint.base58EncodedString
                    })
                    let vm = ReceiveToken.SceneModel(solanaPubkey: pubkey, solanaTokenWallet: nil, isRenBTCWalletCreated: isRenBTCWalletCreated)
                    let vc = ReceiveToken.ViewController(viewModel: vm, isOpeningFromToken: false)
                    analyticsManager.log(event: .mainScreenReceiveOpen)
                    analyticsManager.log(event: .receiveViewed(fromPage: "main_screen"))
                    show(vc, sender: true)
                }
            case .scanQr:
                analyticsManager.log(event: .mainScreenQrOpen)
                analyticsManager.log(event: .scanQrOpen(fromPage: "main_screen"))
                let vc = QrCodeScannerVC()
                vc.callback = qrCodeScannerHandler(code:)
                vc.modalPresentationStyle = .fullScreen
                present(vc, animated: true, completion: nil)
            case .scanQrWithSwiper(let progress, let state):
                MenuHelper.mapGestureStateToInteractor(
                    gestureState: state,
                    progress: progress,
                    interactor: interactor)
                { [weak self] in
                    guard let self = self else {return}
                    self.analyticsManager.log(event: .mainScreenQrOpen)
                    self.analyticsManager.log(event: .scanQrOpen(fromPage: "main_screen"))
                    let vc = QrCodeScannerVC()
                    vc.callback = qrCodeScannerHandler(code:)
                    vc.transitioningDelegate = self
                    vc.modalPresentationStyle = .custom
                    self.present(vc, animated: true, completion: nil)
                }
            case .sendToken(let address):
                let vm = SendToken.ViewModel(walletPubkey: nil, destinationAddress: address, relayMethod: .default)
                let vc = SendToken.ViewController(viewModel: vm)
                show(vc, sender: nil)
                
                analyticsManager.log(event: .mainScreenSendOpen)
                analyticsManager.log(event: .sendViewed(lastScreen: "main_screen"))
            case .swapToken:
                let vm = OrcaSwapV2.ViewModel(initialWallet: nil)
                let vc = OrcaSwapV2.ViewController(viewModel: vm)
                analyticsManager.log(event: .mainScreenSwapOpen)
                analyticsManager.log(event: .swapViewed(lastScreen: "main_screen"))
                show(vc, sender: nil)
            case .settings:
                analyticsManager.log(event: .mainScreenSettingsOpen)
                analyticsManager.log(event: .settingsOpen(lastScreen: "main_screen"))
                
                let vm = Settings.ViewModel(reserveNameHandler: viewModel)
                let vc = Settings.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case .reserveName(let owner):
                let vm = ReserveName.ViewModel(
                    kind: .independent,
                    owner: owner,
                    reserveNameHandler: viewModel
                )
                let vc = ReserveName.ViewController(viewModel: vm)

                show(vc, sender: nil)

                viewModel.nameDidReserveSignal
                    .emit(onNext: { [weak vc] in
                        vc?.back()
                    })
                    .disposed(by: disposeBag)
            case .walletDetail(let wallet):
                guard let pubkey = wallet.pubkey else {return}
                
                analyticsManager.log(event: .mainScreenTokenDetailsOpen(tokenTicker: wallet.token.symbol))
                let vm = WalletDetail.ViewModel(pubkey: pubkey, symbol: wallet.token.symbol)
                let vc = WalletDetail.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case .walletSettings(let wallet):
                guard let pubkey = wallet.pubkey else {return}
                let vm = TokenSettingsViewModel(pubkey: pubkey)
                let vc = TokenSettingsViewController(viewModel: vm)
                present(vc, animated: true, completion: nil)
            case let .closeReserveNameAlert(handler):
                showAlert(
                    title: L10n.proceedWithoutAUsername,
                    message: L10n.anytimeYouWantYouCanEasilyReserveAUsernameByGoingToTheSettings,
                    buttonTitles: [L10n.proceed, L10n.proceedDonTShowAgain],
                    highlightedButtonIndex: 0,
                    completion: { buttonIndex in
                        switch buttonIndex {
                        case 0:
                            handler(.temporary)
                        case 1:
                            handler(.forever)
                        default:
                            assertionFailure("Unknow button")
                        }
                    }
                )
            }
        }
        
        private func qrCodeScannerHandler(code: String) -> Bool {
            if NSRegularExpression.publicKey.matches(code) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.viewModel.navigate(to: .sendToken(address: code))
                }
                return true
            }
            return false
        }
    }
}

extension Home.ViewController: UIViewControllerTransitioningDelegate {
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
