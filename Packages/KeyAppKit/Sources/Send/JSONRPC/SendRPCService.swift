import Foundation
import KeyAppNetworking

public class SendRPCService {
    let host: String
    let jsonrpcClient: JSONRPCHTTPClient

    public init(
        host: String,
        urlSession: HTTPURLSession = URLSession.shared
    ) {
        self.host = host
        jsonrpcClient = .init(urlSession: urlSession)
    }

    public func getCompensationTokens() async throws -> [String] {
        try await jsonrpcClient.request(
            baseURL: host,
            body: .init(
                method: "get_compensation_tokens"
            )
        )
    }

    public func transfer(
        userWallet: String,
        mint: String?,
        amount: UInt64,
        recipient: String,
        transferMode: SendServiceTransferMode = .exactOut,
        networkFeePayer: SendServiceTransferFeePayer,
        taRentPayer: SendServiceTransferFeePayer
    ) async throws -> SendServiceTransferResponse {
        try await jsonrpcClient.request(
            baseURL: host,
            body: .init(
                method: "transfer",
                params: SendServiceTransferRequest(
                    userWallet: userWallet,
                    mint: mint,
                    amount: "\(amount)",
                    recipient: recipient,
                    options: .init(
                        transferMode: transferMode,
                        networkFeePayer: networkFeePayer,
                        taRentPayer: taRentPayer
                    )
                )
            )
        )
    }

    public func getLimits(
        userWallet: String
    ) async throws -> SendServiceLimitResponse {
        try await jsonrpcClient.request(
            baseURL: host,
            body: .init(
                method: "limits",
                params: ["user_wallet": userWallet]
            )
        )
    }

    public func getTokenAccountRentExempt(
        mints: [String]
    ) async throws -> [String: UInt64] {
        try await jsonrpcClient.request(
            baseURL: host,
            body: .init(
                method: "get_token_account_rent_exempt",
                params: ["mints": mints]
            )
        )
    }
}
