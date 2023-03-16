//
//  JupiterSwapBusinessLogic+Calculate.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/03/2023.
//

import Foundation
import Jupiter

enum JupiterSwapError: Swift.Error {
    case amountFromIsZero
    case fromAndToTokenAreEqual
}

struct JupiterSwapRouteCalculationResult {
    let routes: [Route]
    let selectedRoute: Route?
}

extension JupiterSwapBusinessLogic {
    static func calculateRoute(
        amountFrom: Double?,
        fromTokenAddress: String,
        fromTokenDecimals: Decimals,
        toTokenAddress: String
    ) async throws -> JupiterSwapRouteCalculationResult {
        // get current from amount
        guard let amountFrom, amountFrom > 0
        else {
            throw JupiterSwapError.amountFromIsZero
        }
        
        // assert from token is not equal to toToken
        guard fromTokenAddress != toTokenAddress else {
            throw JupiterSwapError.fromAndToTokenAreEqual
        }
        
        // get lamport
        let amountFromLamports = amountFrom
            .toLamport(decimals: fromTokenDecimals)
        
        // call api to get routes and amount
        let data = try await services.jupiterClient.quote(
            inputMint: state.fromToken.address,
            outputMint: state.toToken.address,
            amount: String(amountFromLamports),
            swapMode: nil,
            slippageBps: state.slippageBps,
            feeBps: nil,
            onlyDirectRoutes: nil,
            userPublicKey: state.account?.publicKey.base58EncodedString,
            enforceSingleTx: nil
        )
        
        // routes
        let routes = data.data
        
        // if pre chosen route is stil available, choose it
        // if not choose the first one
        guard let route = data.data.first(
            where: {$0.id == state.route?.id})
                ?? data.data.first
        else {
            return .init(routes: routes, selectedRoute: nil)
        }
        
        // get all tokens that involved in the swap and get the price
        var tokens = [Token]()
        tokens.append(state.fromToken.token)
        tokens.append(state.toToken.token)
        
        // get prices of transitive tokens
        let mints = route.getMints()
        if mints.count > 2 {
            for mint in mints {
                if let token = state.swapTokens.map(\.token).first(where: {$0.address == mint}) {
                    tokens.append(token)
                }
            }
        }
        
        let tokensPriceMap = ((try? await services.pricesAPI.getCurrentPrices(coins: tokens, toFiat: Defaults.fiat.code)) ?? [:])
            .reduce([String: Double]()) { combined, element in
                guard let value = element.value?.value else { return combined }
                var combined = combined
                combined[element.key.address] = value
                return combined
            }
        
        return await validateAmounts(
            state: state.modified {
                $0.status = .ready
                $0.route = route
                $0.routes = routes
                $0.amountTo = UInt64(route.outAmount)?
                    .convertToBalance(decimals: state.toToken.token.decimals)
                $0.tokensPriceMap = $0.tokensPriceMap
                    .merging(tokensPriceMap, uniquingKeysWith: { (_, new) in new })
            },
            services: services
        )
        
        do {
            
            
            
        }
        catch let error {
            return handle(error: error, for: state)
        }
    }
}
