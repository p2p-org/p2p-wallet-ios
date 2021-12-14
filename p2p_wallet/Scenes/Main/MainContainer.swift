//
//  MainContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation
import RxSwift
import FeeRelayerSwift
import Resolver

class MainContainer {
    // MARK: - Properties
    var solanaSDK: SolanaSDK
    var socket: SolanaSDK.Socket
    let processingTransactionsManager: ProcessingTransactionsManager
    let pricesService: PricesServiceType
    private(set) var walletsViewModel: WalletsViewModel
    
    let renVMLockAndMintService: RenVMLockAndMintServiceType
    let renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
    
    private lazy var orcaSwap: OrcaSwapType = OrcaSwap(
        apiClient: OrcaSwap.APIClient(
            network: Defaults.apiEndPoint.network.cluster
        ),
        solanaClient: solanaSDK,
        accountProvider: solanaSDK,
        notificationHandler: solanaSDK
    )
    
    init() {
        self.solanaSDK = SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: Resolver.resolve())
        self.socket = SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl)
        
        self.pricesService = PricesService(tokensRepository: solanaSDK)
        
        let walletsViewModel = WalletsViewModel(
            solanaSDK: solanaSDK,
            accountNotificationsRepository: socket,
            pricesService: pricesService
        )
        
        self.processingTransactionsManager = ProcessingTransactionsManager(handler: socket, walletsRepository: walletsViewModel, pricesService: pricesService)
        walletsViewModel.processingTransactionRepository  = self.processingTransactionsManager
        self.walletsViewModel = walletsViewModel
        
        // RenVM
        let network: RenVM.Network
        switch solanaSDK.endpoint.network {
        case .mainnetBeta:
            network = .mainnet
        case .testnet, .devnet:
            network = .testnet
        }
        
        let rpcClient = RenVM.RpcClient(network: network)
        
        self.renVMLockAndMintService = RenVM.LockAndMint.Service(
            rpcClient: rpcClient,
            solanaClient: solanaSDK,
            account: solanaSDK.accountStorage.account!,
            sessionStorage: RenVM.LockAndMint.SessionStorage(),
            transactionHandler: socket
        )
        
        self.renVMBurnAndReleaseService = RenVM.BurnAndRelease.Service(
            rpcClient: rpcClient,
            solanaClient: solanaSDK,
            account: solanaSDK.accountStorage.account!,
            transactionStorage: RenVM.BurnAndRelease.TransactionStorage(),
            transactionHandler: socket
        )
        
        defer {
            socket.connect()
            pricesService.startObserving()
        }
    }
    
    deinit {
        socket.disconnect()
        pricesService.stopObserving()
    }
    
    func makeMainViewController(authenticateWhenAppears: Bool) -> MainViewController {
        MainViewController(scenesFactory: self, authenticateWhenAppears: authenticateWhenAppears)
    }
    
    func makeTabBarVC() -> TabBarVC {
        TabBarVC(scenesFactory: self)
    }
    
    func makeHomeViewController() -> Home.ViewController {
        let vm = Home.ViewModel(walletsRepository: walletsViewModel, pricesService: pricesService)
        return .init(viewModel: vm, scenesFactory: self)
    }
    
    func makeInvestmentsViewController() -> InvestmentsViewController {
        let newsViewModel = NewsViewModel()
        let defisViewModel = DefisViewModel()
        let investmentsViewModel = InvestmentsViewModel(
            newsViewModel: newsViewModel,
            defisViewModel: defisViewModel
        )
        return InvestmentsViewController(viewModel: investmentsViewModel)
    }
    
    func makeWalletDetailViewController(pubkey: String, symbol: String) -> WalletDetail.ViewController {
        let viewModel = WalletDetail.ViewModel(
            pubkey: pubkey,
            symbol: symbol,
            walletsRepository: walletsViewModel,
            processingTransactionRepository: processingTransactionsManager,
            pricesService: pricesService,
            transactionsRepository: solanaSDK,
            feeRelayer: FeeRelayer(),
            notificationsRepository: walletsViewModel
        )
        
        return WalletDetail.ViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeTransactionInfoViewController(transaction: SolanaSDK.ParsedTransaction) -> TransactionInfoViewController
    {
        let viewModel = TransactionInfoViewModel(transaction: transaction)
        return TransactionInfoViewController(viewModel: viewModel)
    }
    
    func makeBuyTokenViewController(token: BuyToken.CryptoCurrency) throws -> UIViewController
    {
        try BuyToken.ViewController(token: token, repository: walletsViewModel)
    }
    
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.Scene? {
        guard let pubkey = try? SolanaSDK.PublicKey(string: walletsViewModel.nativeWallet?.pubkey) else {return nil}
        let tokenWallet = walletsViewModel.getWallets().first(where: {$0.pubkey == tokenWalletPubkey})
        
        let isDevnet = solanaSDK.endpoint.network == .devnet
        let renBTCMint = isDevnet ? SolanaSDK.PublicKey.renBTCMintDevnet: SolanaSDK.PublicKey.renBTCMint
        
        let isRenBTCWalletCreated = walletsViewModel.getWallets().contains(where: {
            $0.token.address == renBTCMint.base58EncodedString
        })
        
        let viewModel = ReceiveToken.SceneModel(
            solanaPubkey: pubkey,
            solanaTokenWallet: tokenWallet,
            tokensRepository: solanaSDK,
            renVMService: renVMLockAndMintService,
            isRenBTCWalletCreated: isRenBTCWalletCreated,
            associatedTokenAccountHandler: solanaSDK
        )
        return ReceiveToken.Scene(viewModel: viewModel)
    }
    
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController {
        let vm = SendToken.ViewModel(
            repository: walletsViewModel,
            pricesService: pricesService,
            walletPubkey: walletPubkey,
            destinationAddress: destinationAddress,
            apiClient: solanaSDK,
            renVMBurnAndReleaseService: renVMBurnAndReleaseService
        )
        return .init(viewModel: vm, scenesFactory: self)
    }
    
    func makeSwapTokenViewController(provider: SwapProvider, fromWallet wallet: Wallet?) -> UIViewController
    {
        let feeService = FeeService(apiClient: solanaSDK)
        switch provider {
        case .orca:
            let vm = OrcaSwapV2.ViewModel(
                feeService: feeService,
                orcaSwap: orcaSwap,
                walletsRepository: walletsViewModel,
                initialWallet: wallet ?? walletsViewModel.nativeWallet
                )
            return OrcaSwapV2.ViewController(viewModel: vm, scenesFactory: self)
        case .serum:
            let provider = SerumSwap(
                client: solanaSDK,
                accountProvider: solanaSDK,
                tokenListContainer: solanaSDK,
                signatureNotificationHandler: solanaSDK
            )
            let vm = SerumSwapV1.ViewModel(
                provider: provider,
                feeAPIClient: solanaSDK,
                walletsRepository: walletsViewModel,
                sourceWallet: wallet ?? walletsViewModel.nativeWallet
            )
            let vc = SerumSwapV1.ViewController(viewModel: vm, scenesFactory: self)
            return vc
        }
    }
    
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool, handler: WalletDidSelectHandler) -> ChooseWallet.ViewController
    {
        let viewModel = ChooseWallet.ViewModel(
            myWallets: walletsViewModel.getWallets(),
            handler: handler,
            tokensRepository: solanaSDK,
            showOtherWallets: showOtherWallets
        )
        
        viewModel.customFilter = customFilter
        return ChooseWallet.ViewController(viewModel: viewModel)
    }
    
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController {
        let viewModel = ProcessTransaction.ViewModel(
            transactionType: transactionType,
            request: request,
            transactionHandler: processingTransactionsManager,
            walletsRepository: walletsViewModel,
            pricesService: pricesService,
            apiClient: solanaSDK
        )
        return ProcessTransaction.ViewController(viewModel: viewModel)
    }
    
    // MARK: - Profile VCs
    func makeBackupManuallyVC() -> BackupManuallyVC {
        BackupManuallyVC()
    }
    
    func makeBackupShowPhrasesVC() -> BackupShowPhrasesVC {
        BackupShowPhrasesVC()
    }
    
    func makeSettingsVC(reserveNameHandler: ReserveNameHandler) -> Settings.ViewController {
        let vm = Settings.ViewModel(reserveNameHandler: reserveNameHandler, changeFiatResponder: self, renVMService: renVMLockAndMintService)
        return .init(viewModel: vm)
    }
    
    func makeDAppContainerViewController(dapp: DApp) -> DAppContainer.ViewController {
        .init(walletsRepository: walletsViewModel, dapp: dapp)
    }
    
    // MARK: - Reserve name
    func makeReserveNameVC(owner: String, handler: ReserveNameHandler) -> ReserveName.ViewController {
        let vm = ReserveName.ViewModel(
            canSkip: false,
            owner: owner,
            nameService: Resolver.resolve(),
            reserveNameHandler: handler
        )
        let vc = ReserveName.ViewController(viewModel: vm)

        return vc
    }
    
    // MARK: - Token edit
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController {
        TokenSettingsViewController(
            viewModel: TokenSettingsViewModel(
                walletsRepository: walletsViewModel,
                pubkey: pubkey,
                solanaSDK: solanaSDK,
                pricesService: pricesService
            ),
            scenesFactory: self
        )
    }
    
    // MARK: - Helpers
    func changeFiat(to fiat: Fiat) {
        Defaults.fiat = fiat
        pricesService.clearCurrentPrices()
        pricesService.fetchAllTokensPrice()
    }
}

extension MainContainer: TabBarScenesFactory,
                         OrcaSwapV2ScenesFactory,
                         SwapTokenScenesFactory,
                         WalletDetailScenesFactory,
                         SendTokenScenesFactory,
                         HomeScenesFactory,
                         ChangeFiatResponder,
                         TokenSettingsScenesFactory,
                         _MainScenesFactory {}
