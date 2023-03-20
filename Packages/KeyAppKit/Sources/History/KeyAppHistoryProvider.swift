import Foundation
import KeyAppKitCore
import Onboarding
import SolanaSwift

public protocol KeyAppHistoryProvider {
    func transactions(secretKey: Data, pubKey: String, mint: String?, offset: Int, limit: Int) async throws -> [HistoryTransaction]
}

public enum KeyAppHistoryProviderError: Error {
    case any(code: Int, message: String)
}

public class KeyAppHistoryProviderImpl: KeyAppHistoryProvider {
    let uuid = UUID()
    private let endpoint: URL
    private let networkManager: Onboarding.NetworkManager = URLSession.shared

    public init(endpoint: String) {
        self.endpoint = URL(string: endpoint)!
    }

    public func transactions(secretKey: Data, pubKey: String, mint: String?, offset: Int, limit: Int = 100) async throws -> [HistoryTransaction] {
        var params = TransactionsRequestParams(
            pubKey: pubKey,
            limit: UInt64(limit),
            offset: UInt64(offset),
            mint: mint
        )
        try params.signed(secretKey: secretKey)
        // Prepare
        var request = createDefaultRequest()

        let rpcRequest = JSONRPCRequest(id: uuid.uuidString, method: "get_transactions", params: params)
        request.httpBody = try JSONEncoder().encode(rpcRequest)

        // Request
        let responseData = try await networkManager.requestData(request: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try JSONDecoder().decode(KeyAppKitCore.JSONRPCResponse<HistoryTransactionResult, String>.self, from: responseData)
        if let error = response.error {
            throw KeyAppHistoryProviderError.any(code: error.code, message: error.message)
        }

        return response.result?.items ?? []
    }

    private func createDefaultRequest(method: String = "POST") -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.setValue("P2PWALLET_MOBILE", forHTTPHeaderField: "CHANNEL_ID")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }
}

internal struct TransactionsRequestParams: Codable {
    var pubKey: String
    var limit: UInt64
    var offset: UInt64
    var mint: String?
    var signature: String?

    enum CodingKeys: String, CodingKey {
        case pubKey = "user_id"
        case limit
        case offset
        case mint
        case signature
    }
}

extension TransactionsRequestParams: Onboarding.Signature {
    mutating func signed(secretKey: Data) throws {
        signature = try signAsBase58(secretKey: secretKey)
    }

    func serialize(to writer: inout Data) throws {
        try pubKey.serialize(to: &writer)
        try offset.serialize(to: &writer)
        try limit.serialize(to: &writer)

        if let mint {
            try UInt8(1).serialize(to: &writer)
            try mint.serialize(to: &writer)
        } else {
            try UInt8(0).serialize(to: &writer)
        }
    }
}
