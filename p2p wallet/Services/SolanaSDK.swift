//
//  SolanaSDK.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import Foundation

protocol SolanaSDK {
    static var shared: Self {get}
}

extension SolanaSDK {
    #if DEBUG
    var endpoint: String { "http://localhost:8899/" }
    #else
    var endpoint: String { "" }
    #endif
}

struct SolanaSDKJS: SolanaSDK {
    // MARK: - Singleton
    static let shared = SolanaSDKJS()
    private init() {}
    
    // MARK: - Methods
    
}
