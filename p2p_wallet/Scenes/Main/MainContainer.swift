//
//  MainContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation
import RxSwift
import FeeRelayerSwift

class MainContainer {
    // MARK: - Properties
    var solanaSDK: SolanaSDK
    var socket: SolanaSDK.Socket
    let processingTransactionsManager: ProcessingTransactionsManager
    let pricesManager: PricesManager
    private(set) var walletsViewModel: WalletsViewModel
    
    let renVMLockAndMintService: RenVMLockAndMintServiceType
    let renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
    
    init() {
        self.solanaSDK = SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: Resolver.resolve())
        self.socket = SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl)
        
        self.pricesManager = PricesManager(tokensRepository: solanaSDK, pricesStorage: UserDefaultsPricesStorage(), fetcher: CryptoComparePricesFetcher(), refreshAfter: 2 * 1000) // 2 minutes
        
        let walletsViewModel = WalletsViewModel(
            solanaSDK: solanaSDK,
            accountNotificationsRepository: socket,
            pricesRepository: pricesManager
        )
        
        self.processingTransactionsManager = ProcessingTransactionsManager(handler: socket, walletsRepository: walletsViewModel, pricesRepository: pricesManager)
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
            pricesManager.startObserving()
        }
    }
    
    deinit {
        socket.disconnect()
        pricesManager.stopObserving()
    }
    
    func makeMainViewController(authenticateWhenAppears: Bool) -> MainViewController {
        MainViewController(authenticateWhenAppears: authenticateWhenAppears)
    }
    
    func makeTabBarVC() -> TabBarVC {
        TabBarVC()
    }
    
    // MARK: - Authentication
    func makeLocalAuthVC() -> LocalAuthVC {
        LocalAuthVC()
    }
    
    // MARK: - Reset pincode with seed phrases
    func makeResetPinCodeWithSeedPhrasesViewController() -> ResetPinCodeWithSeedPhrases.ViewController
    {
        .init()
    }
    
    func makeHomeViewController() -> HomeViewController {
        let vm = HomeViewModel(walletsRepository: walletsViewModel)
        return HomeViewController(viewModel: vm)
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
    
    func makeMyProductsViewController() -> MyProductsViewController {
        let viewModel = MyProductsViewModel(walletsRepository: walletsViewModel)
        return MyProductsViewController(viewModel: viewModel)
    }
    
    func makeWalletDetailViewController(pubkey: String, symbol: String) -> WalletDetail.ViewController {
        let viewModel = WalletDetail.ViewModel(
            pubkey: pubkey,
            symbol: symbol,
            walletsRepository: walletsViewModel,
            processingTransactionRepository: processingTransactionsManager,
            pricesRepository: pricesManager,
            transactionsRepository: solanaSDK,
            feeRelayer: FeeRelayer(),
            notificationsRepository: walletsViewModel
        )
        
        return WalletDetail.ViewController(viewModel: viewModel)
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
    
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.ViewController? {
        guard let pubkey = try? SolanaSDK.PublicKey(string: walletsViewModel.nativeWallet?.pubkey) else {return nil}
        let tokenWallet = walletsViewModel.getWallets().first(where: {$0.pubkey == tokenWalletPubkey})
        
        let isDevnet = solanaSDK.endpoint.network == .devnet
        let renBTCMint = isDevnet ? SolanaSDK.PublicKey.renBTCMintDevnet: SolanaSDK.PublicKey.renBTCMint
        
        let isRenBTCWalletCreated = walletsViewModel.getWallets().contains(where: {
            $0.token.address == renBTCMint.base58EncodedString
        })
        
        let viewModel = ReceiveToken.ViewModel(
            solanaPubkey: pubkey,
            solanaTokenWallet: tokenWallet,
            tokensRepository: solanaSDK,
            renVMService: renVMLockAndMintService,
            isRenBTCWalletCreated: isRenBTCWalletCreated,
            associatedTokenAccountHandler: solanaSDK
        )
        return ReceiveToken.ViewController(viewModel: viewModel)
    }
    
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController {
        let vm = SendToken.ViewModel(
            repository: walletsViewModel,
            walletPubkey: walletPubkey,
            destinationAddress: destinationAddress,
            apiClient: solanaSDK,
            renVMBurnAndReleaseService: renVMBurnAndReleaseService
        )
        let vc = SendToken.ViewController(viewModel: vm)
        return vc
    }
    
    func makeSwapTokenViewController(provider: SwapProvider, fromWallet wallet: Wallet?) -> CustomPresentableViewController
    {
        switch provider {
        case .orca:
            let vm = OrcaSwap.ViewModel(
                solWallet: walletsViewModel.nativeWallet,
                apiClient: solanaSDK
            )
            vm.input.sourceWallet.accept(wallet ?? walletsViewModel.nativeWallet)
            return OrcaSwap.ViewController(viewModel: vm)
        case .serum:
            let provider = SerumSwap(
                client: solanaSDK,
                accountProvider: solanaSDK,
                tokenListContainer: solanaSDK,
                signatureNotificationHandler: socket
            )
            let vm = SwapToken.ViewModel(
                provider: provider,
                apiClient: solanaSDK,
                walletsRepository: walletsViewModel,
                sourceWallet: wallet ?? walletsViewModel.nativeWallet
            )
            let vc = SwapToken.ViewController(viewModel: vm)
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
            pricesRepository: pricesManager,
            apiClient: solanaSDK
        )
        return ProcessTransaction.ViewController(viewModel: viewModel)
    }
    
    // MARK: - Profile VCs
    func makeProfileVC(reserveNameHandler: ReserveNameHandler) -> ProfileVC {
        ProfileVC(reserveNameHandler: reserveNameHandler)
    }
    
    func makeSettingsVC(reserveNameHandler: ReserveNameHandler) -> Settings.ViewController {
        let vm = Settings.ViewModel(reserveNameHandler: reserveNameHandler, renVMService: renVMLockAndMintService)
        return .init(viewModel: vm)
    }
    
    func makeSelectNetworkVC() -> SelectNetworkVC {
        SelectNetworkVC(renVMService: renVMLockAndMintService)
    }
    
    // MARK: - Token edit
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController {
        TokenSettingsViewController(
            viewModel: TokenSettingsViewModel(
                walletsRepository: walletsViewModel,
                pubkey: pubkey,
                solanaSDK: solanaSDK,
                pricesRepository: pricesManager
            )
        )
    }
    
    // MARK: - Helpers
    func changeFiat(to fiat: Fiat) {
        Defaults.fiat = fiat
        pricesManager.currentPrices.accept([:])
        pricesManager.fetchAllTokensPrice()
    }
}

extension MainContainer: TabBarScenesFactory,
                         MyProductsScenesFactory,
                         ProfileScenesFactory,
                         OrcaSwapScenesFactory,
                         SwapTokenScenesFactory,
                         WalletDetailScenesFactory,
                         SendTokenScenesFactory,
                         HomeScenesFactory,
                         ChangeFiatResponder,
                         TokenSettingsScenesFactory,
                         _MainScenesFactory {}
