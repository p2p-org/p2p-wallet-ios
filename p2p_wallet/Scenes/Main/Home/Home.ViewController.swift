//
//  Home.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import Action
import Foundation
import RxCocoa
import UIKit

extension Home {
    class ViewController: BaseVC, TabBarNeededViewController {
        // MARK: - Dependencies

        @Injected private var analyticsManager: AnalyticsManagerType
        private let viewModel: HomeViewModelType

        // MARK: - Properties

        fileprivate let interactor = MenuInteractor()
        private var coordinator: SendToken.Coordinator?

        // MARK: - Initializer

        init(viewModel: HomeViewModelType) {
            self.viewModel = viewModel
            super.init()
            navigationItem.title = L10n.p2PWallet
        }

        // MARK: - Methods

        override func loadView() {
            view = RootView(viewModel: viewModel)
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            analyticsManager.log(event: .mainScreenWalletsOpen)
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.setNavigationBarHidden(false, animated: true)
        }

        override func bind() {
            super.bind()

            let stateObservable = viewModel.walletsRepository
                .stateObservable
                .distinctUntilChanged()

            stateObservable
                .take(until: { $0 == .loaded })
                .asDriver(onErrorJustReturn: .initializing)
                .map { $0 == .loading }
                .drive(onNext: { [weak self] _ in
                    self?.view.showLoadingIndicatorView()
                }, onCompleted: { [weak self] in
                    self?.view.hideLoadingIndicatorView()
                })
                .disposed(by: disposeBag)

            stateObservable
                .asDriver(onErrorJustReturn: .initializing)
                .map { $0 == .error }
                .drive(onNext: { [weak self] hasError in
                    if hasError, self?.viewModel.walletsRepository.getError()?.asAFError != nil {
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
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .buyToken:
                present(
                    BuyTokenSelection.Scene(onTap: { [unowned self] crypto in
                        let vc = BuyPreparing.Scene(
                            viewModel: BuyPreparing.SceneModel(
                                crypto: crypto,
                                exchangeService: Resolver.resolve()
                            )
                        )
                        show(vc, sender: nil)
                    }),
                    animated: true
                )
            case .receiveToken:
                if let pubkey = try? SolanaSDK.PublicKey(string: viewModel.walletsRepository.nativeWallet?.pubkey) {
                    let isDevnet = Defaults.apiEndPoint.network == .devnet
                    let renBTCMint: SolanaSDK.PublicKey = isDevnet ? .renBTCMintDevnet : .renBTCMint

                    let isRenBTCWalletCreated = viewModel.walletsRepository.getWallets().contains(where: {
                        $0.token.address == renBTCMint.base58EncodedString
                    })
                    let vm = ReceiveToken.SceneModel(
                        solanaPubkey: pubkey,
                        solanaTokenWallet: nil,
                        isRenBTCWalletCreated: isRenBTCWalletCreated
                    )
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
            case let .scanQrWithSwiper(progress, state):
                MenuHelper.mapGestureStateToInteractor(
                    gestureState: state,
                    progress: progress,
                    interactor: interactor
                ) { [weak self] in
                    guard let self = self else { return }
                    self.analyticsManager.log(event: .mainScreenQrOpen)
                    self.analyticsManager.log(event: .scanQrOpen(fromPage: "main_screen"))
                    let vc = QrCodeScannerVC()
                    vc.callback = qrCodeScannerHandler(code:)
                    vc.transitioningDelegate = self
                    vc.modalPresentationStyle = .custom
                    self.present(vc, animated: true)
                }
            case let .sendToken(fromAddress, toAddress):
                let vm = SendToken.ViewModel(
                    walletPubkey: fromAddress,
                    destinationAddress: toAddress,
                    relayMethod: .default
                )

                if coordinator == nil, let navigationController = navigationController {
                    coordinator = SendToken.Coordinator(
                        viewModel: vm,
                        navigationController: navigationController
                    )
                    coordinator?.doneHandler = { [weak self] in
                        self?.popToThisViewControllerAndScrollToTop()
                    }
                }
                coordinator?.start()

                analyticsManager.log(event: .mainScreenSendOpen)
                analyticsManager.log(event: .sendViewed(lastScreen: "main_screen"))
            case .swapToken:
                let vm = OrcaSwapV2.ViewModel(initialWallet: nil)
                let vc = OrcaSwapV2.ViewController(viewModel: vm)
                vc.doneHandler = { [weak self] in
                    self?.popToThisViewControllerAndScrollToTop()
                }
                analyticsManager.log(event: .mainScreenSwapOpen)
                analyticsManager.log(event: .swapViewed(lastScreen: "main_screen"))
                show(vc, sender: nil)
            case .settings:
                analyticsManager.log(event: .mainScreenSettingsOpen)
                analyticsManager.log(event: .settingsOpen(lastScreen: "main_screen"))

                let vm = Settings.ViewModel()
                let vc = Settings.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case .reserveName:
                guard let owner = viewModel.getOwner() else { return }
                let vm = ReserveName.ViewModel(
                    kind: .independent,
                    owner: owner,
                    reserveNameHandler: viewModel,
                    goBackOnCompletion: true,
                    checkBeforeReserving: true
                )
                let vc = ReserveName.ViewController(viewModel: vm)

                show(vc, sender: nil)
            case let .walletDetail(wallet):
                guard let pubkey = wallet.pubkey else { return }

                analyticsManager.log(event: .mainScreenTokenDetailsOpen(tokenTicker: wallet.token.symbol))
                let vm = WalletDetail.ViewModel(pubkey: pubkey, symbol: wallet.token.symbol)
                let vc = WalletDetail.ViewController(viewModel: vm)
                vc.processingTransactionDoneHandler = { [weak self] in
                    self?.popToThisViewControllerAndScrollToTop()
                }
                show(vc, sender: nil)
            case let .walletSettings(wallet):
                guard let pubkey = wallet.pubkey else { return }
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
            case .feedback:
                tabBar()?.moveToPage(10)
            case .backup:
                let vm = Settings.Backup.ViewModel()
                let vc = Settings.Backup.ViewController(viewModel: vm, dismissAfterBackup: true)

                show(vc, sender: nil)
                return
            }
        }

        private func popToThisViewControllerAndScrollToTop() {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.viewModel.scrollToTop()
            }
            navigationController?.popToRootViewController(animated: true)
            CATransaction.commit()
        }

        private func qrCodeScannerHandler(code: String) -> Bool {
            if NSRegularExpression.publicKey.matches(code) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.viewModel.navigate(to: .sendToken(toAddress: code))
                }
                return true
            }
            return false
        }
    }
}

extension Home.ViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented _: UIViewController,
        presenting _: UIViewController,
        source _: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        PresentMenuAnimator()
    }

//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        DismissMenuAnimator()
//    }

    func interactionControllerForPresentation(using _: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
    {
        interactor.hasStarted ? interactor : nil
    }
}
