import Foundation

public struct EncodableWrapper: Encodable {
    let wrapped: Encodable

    public func encode(to encoder: Encoder) throws {
        try wrapped.encode(to: encoder)
    }
}

public struct RequestType {
    // MARK: - Properties

    let path: String
    private let params: EncodableWrapper

    // MARK: - Initializer

    public init(path: String, params: Encodable) {
        self.path = path
        self.params = EncodableWrapper(wrapped: params)
    }

    // MARK: - Getters

    public func getParams() throws -> Data {
        try JSONEncoder().encode(params)
    }

    // MARK: - Builders

//
//        public static func compensationSwapToken(_ params: Compensation.SwapTokensParams) -> RequestType {
//            .init(path: "/swap_spl_token_with_fee_compensation", params: params)
//        }

    public static func rewardTransferSOL(_ params: TransferSolParams) -> RequestType {
        .init(path: "/transfer_sol", params: params)
    }

    public static func rewardTransferSPLToken(_ params: TransferSPLTokenParams) -> RequestType {
        .init(path: "/transfer_spl_token", params: params)
    }

    public static func relayTopUpWithSwap(_ params: TopUpWithSwapParams) -> RequestType {
        .init(path: "/relay_top_up_with_swap", params: params)
    }

    public static func relayTransaction(_ params: RelayTransactionParam) -> RequestType {
        .init(path: "/relay_transaction", params: params)
    }

    public static func signRelayTransaction(_ params: RelayTransactionParam) -> RequestType {
        .init(path: "/sign_relay_transaction", params: params)
    }

    public static func signRelayTransaction(_ params: SignRelayTransactionParam) -> RequestType {
        .init(path: "/sign_relay_transaction", params: params)
    }
}
