// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public class JupiterRestClientAPI: JupiterAPI {
    private let host: String
    private let tokensHost: String?

    public init(host: String, tokensHost: String? = nil, version: Version) {
        self.host = host + "/" + version.rawValue
        self.tokensHost = tokensHost
    }
    
    public func getTokens() async throws -> [Token] {
        let (data, _) = try await URLSession.shared.data(from: URL(string: "\(tokensHost ?? host)/tokens")!)
        return try JSONDecoder().decode([Token].self, from: data)
    }

    public func quote(
        inputMint: String,
        outputMint: String,
        amount: String,
        swapMode: SwapMode?,
        slippageBps: Int?,
        feeBps: Int?,
        onlyDirectRoutes: Bool?,
        userPublicKey: String?,
        enforceSingleTx: Bool?
    ) async throws -> Response<[Route]> {
        guard var urlComponent = URLComponents(string: host + "/quote") else { throw JupiterError.invalidURL }

        // Queries
        var queries: [URLQueryItem] = [
            .init(name: "inputMint", value: inputMint),
            .init(name: "outputMint", value: outputMint),
            .init(name: "amount", value: amount),
            .init(name: "userPublicKey", value: userPublicKey),
        ]

        if let swapMode = swapMode {
            queries.append(.init(name: "swapMode", value: swapMode.rawValue))
        }
        if let slippageBps = slippageBps {
            queries.append(.init(name: "slippageBps", value: String(slippageBps)))
        }
        if let onlyDirectRoutes = onlyDirectRoutes {
            queries.append(.init(name: "onlyDirectRoutes", value: String(onlyDirectRoutes)))
        }
        if let enforceSingleTx = enforceSingleTx {
            queries.append(.init(name: "enforceSingleTx", value: String(enforceSingleTx)))
        }
        if let feeBps = feeBps {
            queries.append(.init(name: "feeBps", value: String(feeBps)))
        }
        urlComponent.queryItems = queries

        guard let url = urlComponent.url else { throw JupiterError.invalidURL }
        let request = URLRequest(url: url)
        print(request.cURL())
        let (data, _) = try await URLSession.shared.data(for: request)
        print(String(data: data, encoding: .utf8) ?? "")
        return try JSONDecoder().decode(Response<[Route]>.self, from: data)
    }

    public func swap(
        route: Route,
        userPublicKey: String,
        wrapUnwrapSol: Bool,
        feeAccount: String?,
        asLegacyTransaction: Bool?,
        computeUnitPriceMicroLamports: Int?,
        destinationWallet: String?
    ) async throws -> String? {
        struct PostData: Codable {
            let route: Route
            let userPublicKey: String
            let wrapUnwrapSol: Bool
            let feeAccount: String?
            let asLegacyTransaction: Bool?
            let computeUnitPriceMicroLamports: Int?
            let destinationWallet: String?
        }

        struct ResponseData: Codable {
            let swapTransaction: String?
        }

        guard let url = URL(string: host + "/swap") else { throw JupiterError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(PostData(
            route: route,
            userPublicKey: userPublicKey,
            wrapUnwrapSol: wrapUnwrapSol,
            feeAccount: feeAccount,
            asLegacyTransaction: asLegacyTransaction,
            computeUnitPriceMicroLamports: computeUnitPriceMicroLamports,
            destinationWallet: destinationWallet
        ))

        print(request.cURL())
        let (data, _) = try await URLSession.shared.data(for: request)
        print(String(data: data, encoding: .utf8) ?? "")
        return try JSONDecoder().decode(ResponseData.self, from: data).swapTransaction
    }

    public func routeMap() async throws -> RouteMap {
        // download json
        guard let url = URL(string: host + "/indexed-route-map") else { throw JupiterError.invalidURL }
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)

        // map route
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let mintKeys = json["mintKeys"] as? [String],
            let indexedRouteMap = json["indexedRouteMap"] as? [String: [Int]],
            mintKeys.first != "[object Map Iterator]"
        else { throw JupiterError.invalidResponse }

        try Task.checkCancellation()
        var generatedIndexesRouteMap: [String: [String]] = [:]
        for (key, value) in indexedRouteMap {
            guard let key = Int(key), mintKeys.count > key else {
                continue
            }
            generatedIndexesRouteMap[mintKeys[key]] = value.compactMap {
                mintKeys[safe: $0]
            }
        }

        return .init(
            mintKeys: mintKeys,
            indexesRouteMap: generatedIndexesRouteMap
        )
    }
}


public extension JupiterRestClientAPI {
    enum Version: String {
        case v3
        case v4
    }
}
