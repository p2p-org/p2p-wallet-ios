//
//  GlobalAppState.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.10.2022.
//

import Foundation
import NameService

class GlobalAppState: ObservableObject {
    static let shared = GlobalAppState()
    
    // App logic
    @Published var shouldPlayAnimationOnHome: Bool = false
    @Published var preferDirectSwap: Bool = true
    
    // Debug features
    @Published var forcedWalletAddress: String = ""
    @Published var forcedFeeRelayerEndpoint: String = ""
    
    // Endpoints
    @Published var nameServiceEndpoint: String = NameServiceImpl.endpoint

    private init() {}
}
