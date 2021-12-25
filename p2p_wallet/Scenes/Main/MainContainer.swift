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
}
