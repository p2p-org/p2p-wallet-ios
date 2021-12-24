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
    func makeBuyTokenViewController(token: Set<BuyProviders.Crypto>) throws -> UIViewController {
        BuyRoot.ViewController(crypto: token, walletRepository: walletsViewModel)
    }
    
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.ViewController? {
        guard let pubkey = try? SolanaSDK.PublicKey(string: walletsViewModel.nativeWallet?.pubkey) else {return nil}
        let tokenWallet = walletsViewModel.getWallets().first(where: {$0.pubkey == tokenWalletPubkey})
        
        let isDevnet = solanaSDK.endpoint.network == .devnet
        let renBTCMint = isDevnet ? SolanaSDK.PublicKey.renBTCMintDevnet : SolanaSDK.PublicKey.renBTCMint
        
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
        return ReceiveToken.ViewController(viewModel: viewModel)
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
    
    func makeSwapTokenViewController(provider: SwapProvider, fromWallet wallet: Wallet?) -> UIViewController {
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
    
    func makeChooseWalletViewController(
        title: String?,
        customFilter: ((Wallet) -> Bool)?,
        showOtherWallets: Bool,
        selectedWallet: Wallet?,
        handler: WalletDidSelectHandler) -> ChooseWallet.ViewController
    {
        let viewModel = ChooseWallet.ViewModel(
            myWallets: walletsViewModel.getWallets(),
            selectedWallet: selectedWallet,
            handler: handler,
            tokensRepository: solanaSDK,
            showOtherWallets: showOtherWallets
        )
        
        viewModel.customFilter = customFilter
        return ChooseWallet.ViewController(title: title, viewModel: viewModel)
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
            kind: .independent,
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
    _MainScenesFactory {
}
