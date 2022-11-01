//
//  GlobalAppState.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.10.2022.
//

import Foundation

class GlobalAppState: ObservableObject {
    static let shared = GlobalAppState()
    
    @Published var shouldPlayAnimationOnHome: Bool = false
    
    @Published var forcedWalletAddress: String = ""

    private init() {}
}
