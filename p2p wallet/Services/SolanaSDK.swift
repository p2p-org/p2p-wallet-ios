//
//  SolanaSDK.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import Foundation

struct SolanaSDK {
    // MARK: - Properties
    #if DEBUG
    let endpoint = "https://testnet.solana.com"
    #else
    let endpoint = ""
    #endif
    
    // MARK: - Singleton
    static var shared = SolanaSDK()
    private init() {}
    
    // MARK: - Methods
    
}
