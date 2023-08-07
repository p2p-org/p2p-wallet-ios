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

public class SendProviderImpl {
    let client: HTTPJSONRPCCLient

    public init(client: HTTPJSONRPCCLient) {
        self.client = client
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
            let amount: UInt64
            let recipient: String
            let options: TransferOptions
        }

        return try await client.call(
            method: "transfer",
            params: Params(
                userWallet: userWallet,
                mint: mint,
                amount: amount,
                recipient: recipient,
                options: options
            )
        )
    }

    func version() async throws -> String {
        try await client.call(method: "version", params: HTTPJSONRPCCLient.EmptyParams())
    }
}
