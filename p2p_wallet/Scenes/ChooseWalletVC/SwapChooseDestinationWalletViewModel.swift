//
//  SwapChooseDestinationWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/02/2021.
//

import Foundation
import RxSwift

class SwapChooseDestinationViewModel: WalletsVM {
    let walletsVM: WalletsVM
    
    init(solanaSDK: SolanaSDK, socket: SolanaSDK.Socket, walletsVM: WalletsVM) {
        self.walletsVM = walletsVM
        super.init(solanaSDK: solanaSDK, socket: socket)
    }
    
    override var request: Single<[Wallet]> {
        // get uncreated wallet
        var wallets = SolanaSDK.Token.getSupportedTokens(network: Defaults.network)?.compactMap {$0 != nil ? Wallet(programAccount: $0!) : nil} ?? []
        
        for i in 0..<wallets.count {
            if let price = PricesManager.shared.currentPrice(for: wallets[i].symbol)
            {
                wallets[i].price = price
            }
        }
        
        var uncreatedWallets = wallets
            .filter { newWallet in
                !walletsVM.data.contains(where: {$0.mintAddress == newWallet.mintAddress})
            }
        
        let getUncreatedWalletInfo: Single<[Wallet]> =
            Single<Int>.zip(
                uncreatedWallets
                    .map {
                        guard let mint = try? SolanaSDK.PublicKey(string: $0.mintAddress)
                        else {return .error(SolanaSDK.Error.other("Mint address is not valid"))}
                        return solanaSDK.getMintData(mintAddress: mint)
                            .map {Int($0.decimals)}
                            .catchErrorJustReturn(0)
                    }
            )
                .map {decimalInfos -> [Wallet] in
                    for (index, decimals) in decimalInfos.enumerated() {
                        uncreatedWallets[index].decimals = decimals
                    }
                    return uncreatedWallets
                }
        
        var request: Single<[Wallet]>!
        if walletsVM.data.isEmpty {
            request = super.request
        } else {
            request = .just(walletsVM.data)
        }
        return request
            .flatMap {wallets in
                return getUncreatedWalletInfo
                    .map {wallets + $0}
            }
    }
}
