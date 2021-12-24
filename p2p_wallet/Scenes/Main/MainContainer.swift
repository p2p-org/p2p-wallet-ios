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
//    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.ViewController? {
//        guard let pubkey = try? SolanaSDK.PublicKey(string: walletsViewModel.nativeWallet?.pubkey) else {return nil}
//        let tokenWallet = walletsViewModel.getWallets().first(where: {$0.pubkey == tokenWalletPubkey})
//
//        let isDevnet = solanaSDK.endpoint.network == .devnet
//        let renBTCMint = isDevnet ? SolanaSDK.PublicKey.renBTCMintDevnet : SolanaSDK.PublicKey.renBTCMint
//
//        let isRenBTCWalletCreated = walletsViewModel.getWallets().contains(where: {
//            $0.token.address == renBTCMint.base58EncodedString
//        })
//
//        let viewModel = ReceiveToken.SceneModel(
//            solanaPubkey: pubkey,
//            solanaTokenWallet: tokenWallet,
//            tokensRepository: solanaSDK,
//            renVMService: renVMLockAndMintService,
//            isRenBTCWalletCreated: isRenBTCWalletCreated,
//            associatedTokenAccountHandler: solanaSDK
//        )
//        return ReceiveToken.ViewController(viewModel: viewModel)
//    }
    
    func makeSettingsVC(reserveNameHandler: ReserveNameHandler) -> Settings.ViewController {
        let vm = Settings.ViewModel(reserveNameHandler: reserveNameHandler, changeFiatResponder: self, renVMService: renVMLockAndMintService)
        return .init(viewModel: vm)
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

extension MainContainer: ChangeFiatResponder {}
