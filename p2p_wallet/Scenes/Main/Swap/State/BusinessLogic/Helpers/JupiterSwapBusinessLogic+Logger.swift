//
//  JupiterSwapBusinessLogic+Logger.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/05/2023.
//

import Foundation
import Resolver
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func sendErrorLog(_ errorDetail: SwapErrorDetail) {
        Task.detached {
            let logger = Resolver.resolve(SwapErrorLogger.self)
            try await logger.logErrorDetail(errorDetail)
        }
    }
}
