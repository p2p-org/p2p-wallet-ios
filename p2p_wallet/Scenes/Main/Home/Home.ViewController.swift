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
        @Injected private var viewModel: HomeViewModelType
        
        // MARK: - Properties
        fileprivate let interactor = MenuInteractor()
        
        // MARK: - Initializer
        
        // MARK: - Methods
        override func loadView() {
            view = RootView()
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
                let vc = BuyRoot.ViewController()
                show(vc, sender: nil)
            case .receiveToken:
                if let pubkey = try? SolanaSDK.PublicKey(string: viewModel.walletsRepository.nativeWallet?.pubkey) {
                    let isDevnet = Defaults.apiEndPoint.network == .devnet
                    let renBTCMint: SolanaSDK.PublicKey = isDevnet ? .renBTCMintDevnet : .renBTCMint
                    
                    let isRenBTCWalletCreated = viewModel.walletsRepository.getWallets().contains(where: {
                        $0.token.address == renBTCMint.base58EncodedString
                    })
                    let vc = ReceiveToken.ViewController(solanaPubkey: pubkey, solanaTokenWallet: nil, isRenBTCWalletCreated: isRenBTCWalletCreated)
                    analyticsManager.log(event: .mainScreenReceiveOpen)
                    analyticsManager.log(event: .receiveOpen(fromPage: "main_screen"))
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
                let vc = SendToken.ViewController(walletPubkey: nil, destinationAddress: address)
                analyticsManager.log(event: .mainScreenSendOpen)
                analyticsManager.log(event: .sendOpen(fromPage: "main_screen"))
                show(vc, sender: nil)
            case .swapToken:
                let vc = OrcaSwapV2.ViewController(initialWallet: nil)
                analyticsManager.log(event: .mainScreenSwapOpen)
                analyticsManager.log(event: .swapOpen(fromPage: "main_screen"))
                self.show(vc, sender: nil)
            case .settings:
                analyticsManager.log(event: .mainScreenSettingsOpen)
                analyticsManager.log(event: .settingsOpen(fromPage: "main_screen"))
                
                let vc = Settings.ViewController(reserveNameHandler: viewModel)
                self.show(vc, sender: nil)
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
                
                let vc = WalletDetail.ViewController(pubkey: pubkey, symbol: wallet.token.symbol)
                show(vc, sender: nil)
            case .walletSettings(let wallet):
                guard let pubkey = wallet.pubkey else {return}
                let vc = TokenSettingsViewController(pubkey: pubkey)
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
