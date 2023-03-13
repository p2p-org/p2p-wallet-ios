// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppKitCore
@testable import Onboarding
import XCTest

class APIGatewayClientImplTests: XCTestCase {
    // func testGetMetadata() async throws {
    //     let client = APIGatewayClientImpl(endpoint: "localhost", networkManager: URLSessionMock())
    //
    //     _ = try await client.getMetadata(
    //         ethAddress: "0x239a3b0ce6dd9f3393e0e552763f7bb27441cc5d",
    //         solanaPrivateKey: "52y2jQVwqQXkNW9R9MsKMcv9ZnJnDwzJqLX4d8noB4LEpuezFQLvAb2rioKsLCChte9ELNYwN29GzVjVVUmvfQ4v",
    //         timestampDevice: Date()
    //     )
    // }

    func testRegisterWallet() async throws {
        var network = URLSessionMock()
        network.handler = { _ in
            let response: JSONRPCResponse<APIGatewayClientResult, BlockErrorData> = .init(
                id: "1",
                jsonrpc: "2.0",
                result: APIGatewayClientResult(status: true),
                error: nil
            )

            return try JSONEncoder().encode(response)
        }

        let privateKey = "52y2jQVwqQXkNW9R9MsKMcv9ZnJnDwzJqLX4d8noB4LEpuezFQLvAb2rioKsLCChte9ELNYwN29GzVjVVUmvfQ4v"
        let client = APIGatewayClientImpl(endpoint: "localhost", networkManager: network)
        try await client.registerWallet(
            solanaPrivateKey: privateKey,
            ethAddress: "123",
            phone: "+442071838750",
            channel: .sms,
            timestampDevice: Date()
        )
    }

    func testConfirmRestoreWallet() async throws {
        var network = URLSessionMock()
        network.handler = { _ in
            let response: JSONRPCResponse<APIGatewayClientConfirmRestoreWalletResult, BlockErrorData> = .init(
                id: "1",
                jsonrpc: "2.0",
                result: APIGatewayClientConfirmRestoreWalletResult(
                    status: true,
                    solanaPublicKey: "",
                    ethereumAddress: "",
                    share: "",
                    payload: "",
                    metadata: ""
                ),
                error: nil
            )

            return try JSONEncoder().encode(response)
        }
        
        let privateKey = "52y2jQVwqQXkNW9R9MsKMcv9ZnJnDwzJqLX4d8noB4LEpuezFQLvAb2rioKsLCChte9ELNYwN29GzVjVVUmvfQ4v"
        let solanaSecretKey = Data(Base58.decode(privateKey))
        let client = APIGatewayClientImpl(endpoint: "localhost", networkManager: network)
        _ = try await client.confirmRestoreWallet(
            solanaPrivateKey: solanaSecretKey,
            phone: "+442071838750",
            otpCode: "1234",
            timestampDevice: Date()
        )
    }
}

private func secureRandomData(count: Int) throws -> Data {
    var bytes = [UInt8](repeating: 0, count: count)

    // Fill bytes with secure random data
    let status = SecRandomCopyBytes(
        kSecRandomDefault,
        count,
        &bytes
    )

    // A status of errSecSuccess indicates success
    if status == errSecSuccess {
        // Convert bytes to Data
        let data = Data(bytes: bytes, count: count)
        return data
    } else {
        // Handle error
        return Data()
    }
}
