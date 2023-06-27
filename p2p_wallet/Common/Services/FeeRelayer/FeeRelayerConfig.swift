//
//  FeeRelayerConfig.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 20.10.2022.
//

import Foundation
import Combine

class FeeRelayConfig: ObservableObject {
    static let shared = FeeRelayConfig()
    
    @Published var disableFeeTransaction: Bool = false
}
