// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum SwapMode: String {
    case exactIn = "ExactIn"
    case exactOut = "ExactOut"
}

public protocol JupiterAPI {
    func getTokens() async throws -> [Token]
    
    func quote(
        inputMint: String,
        outputMint: String,
        amount: String,
        swapMode: SwapMode?,
        slippageBps: Int?,
        feeBps: Int?,
        onlyDirectRoutes: Bool?,
        userPublicKey: String?,
        enforceSingleTx: Bool?
    ) async throws -> Response<[Route]>

    func swap(
        route: Route,
        userPublicKey: String,
        wrapUnwrapSol: Bool,
        feeAccount: String?,
        asLegacyTransaction: Bool?,
        computeUnitPriceMicroLamports: Int?,
        destinationWallet: String?
    ) async throws -> String?
    
    func routeMap() async throws -> RouteMap
}

extension JupiterAPI {
    public func swap(
        route: Route,
        userPublicKey: String,
        wrapUnwrapSol: Bool,
        feeAccount: String?,
        computeUnitPriceMicroLamports: Int?
    ) async throws -> String? {
        try await swap(
            route: route,
            userPublicKey: userPublicKey,
            wrapUnwrapSol: wrapUnwrapSol,
            feeAccount: feeAccount,
            asLegacyTransaction: nil,
            computeUnitPriceMicroLamports: computeUnitPriceMicroLamports,
            destinationWallet: nil
        )
    }
}
