import Foundation
import KeyAppKitCore

public protocol SendProvider {
    func send(
        userWallet: String,
        mint: String?,
        amount: UInt64,
        recipient: String,
        options: TransferOptions
    ) async throws -> SendResponse

    func version() async throws -> String
}

public class SendProviderImpl: SendProvider {
    let client: HTTPJSONRPCCLient

    public init(client: HTTPJSONRPCCLient) {
        self.client = client
        client.encoder.keyEncodingStrategy = .convertToSnakeCase
        client.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    public func send(
        userWallet: String,
        mint: String?,
        amount: UInt64,
        recipient: String,
        options: TransferOptions
    ) async throws -> SendResponse {
        struct Params: Codable {
            let userWallet: String
            let mint: String?
            let amount: String
            let recipient: String
            let options: TransferOptions
        }

        return try await client.call(
            method: "transfer",
            params: Params(
                userWallet: userWallet,
                mint: mint,
                amount: "\(amount)",
                recipient: recipient,
                options: options
            )
        )
    }

    public func version() async throws -> String {
        try await client.call(method: "version", params: HTTPJSONRPCCLient.EmptyParams())
    }
}
