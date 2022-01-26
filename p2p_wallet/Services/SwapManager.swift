//
//  SwapManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/01/2022.
//

import Foundation
import SolanaSwift
import FeeRelayerSwift
import OrcaSwapSwift

protocol SwapManagerType {
}

class SwapManager: SwapManagerType {
    let solanaClient: SolanaSDK
    let accountStorage: SolanaSDKAccountStorage
    let feeRelay: FeeRelayerAPIClientType
    let orcaSwap: OrcaSwapType
    
    init(solanaClient: SolanaSDK, accountStorage: SolanaSDKAccountStorage, feeRelay: FeeRelayerAPIClientType, orcaSwap: OrcaSwapType) {
        self.solanaClient = solanaClient
        self.accountStorage = accountStorage
        self.feeRelay = feeRelay
        self.orcaSwap = orcaSwap
    }
    
    func getSwapInfo(from sourceToken: SolanaSDK.Token, to destinationToken: SolanaSDK.Token) -> SwapInfo {
        // Determine a mode for paying fee
        var payingTokenMode: PayingTokenMode = .any
        if (sourceToken.isNativeSOL && !destinationToken.isNativeSOL) {
            payingTokenMode = .onlySol
        } else if (!sourceToken.isNativeSOL && destinationToken.isNativeSOL) {
            payingTokenMode = .onlySol
        }
        
        return .init(payingTokenMode: payingTokenMode)
    }
    
    func swap() throws {
        let relay = try FeeRelayer.Relay(
            apiClient: feeRelay,
            solanaClient: solanaClient,
            accountStorage: accountStorage,
            orcaSwapClient: orcaSwap
        )
    }
}

extension SwapManager {
    
    enum PayingTokenMode {
        /// Allow to use any token to pay a fee
        case any
        /// Only allow to use native sol to pay a fee
        case onlySol
    }
    
    struct SwapInfo {
        /// This property defines a mode for paying fee.
        let payingTokenMode: PayingTokenMode
    }
}
