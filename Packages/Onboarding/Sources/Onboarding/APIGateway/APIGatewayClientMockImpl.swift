// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public class APIGatewayClientImplMock: APIGatewayClient {
    private var code = "000000"

    public init() {}

    public func getMetadata(
        ethAddress _: String,
        solanaPrivateKey _: String,
        timestampDevice _: Date
    ) async throws -> String {
        ""
    }

    public func registerWallet(
        solanaPrivateKey _: String,
        ethAddress _: String,
        phone: String,
        channel _: APIGatewayChannel,
        timestampDevice _: Date
    ) async throws {
        debugPrint("SMSServiceImplMock code: \(code) for phone \(phone)")
        sleep(1)

        if
            let exep = APIGatewayError(rawValue: -(Int(String(phone.suffix(5))) ?? 0)),
            exep.rawValue != APIGatewayError.invalidOTP.rawValue
        {
            throw exep
        }
    }

    public func confirmRegisterWallet(
        solanaPrivateKey _: String,
        ethAddress _: String,
        share _: String,
        encryptedPayload _: String,
        encryptedMetaData _: String,
        phone _: String,
        otpCode: String,
        timestampDevice _: Date
    ) async throws {
        sleep(1)
        debugPrint("SMSServiceImplMock confirm isConfirmed: \(code == code)")

        if
            let exep = APIGatewayError(rawValue: -(Int(otpCode) ?? 0)),
            exep.rawValue != APIGatewayError.invalidOTP.rawValue
        {
            throw exep
        }

        guard otpCode == code else {
            throw APIGatewayError.invalidOTP
        }
    }

    public func restoreWallet(
        solPrivateKey _: Data,
        phone: String,
        channel _: BindingPhoneNumberChannel,
        timestampDevice _: Date
    ) async throws {
        debugPrint("SMSServiceImplMock code: \(code) for phone \(phone)")
        sleep(1)

        if
            let exep = APIGatewayError(rawValue: -(Int(String(phone.suffix(5))) ?? 0)),
            exep.rawValue != APIGatewayError.invalidOTP.rawValue
        {
            throw exep
        }
    }

    public func confirmRestoreWallet(
        solanaPrivateKey _: Data,
        phone _: String,
        otpCode: String,
        timestampDevice _: Date
    ) async throws -> APIGatewayRestoreWalletResult {
        sleep(1)
        debugPrint("SMSServiceImplMock confirm isConfirmed: \(code == code)")

        if
            let exep = APIGatewayError(rawValue: -(Int(otpCode) ?? 0)),
            exep.rawValue != APIGatewayError.invalidOTP.rawValue
        {
            throw exep
        }

        guard otpCode == code else {
            throw APIGatewayError.invalidOTP
        }

        return .init(
            solanaPublicKey: "SomeSolPublicKey",
            ethereumId: "SomeEthereumID",
            encryptedShare: "SomeCustomeShare",
            encryptedPayload: "SomePayload",
            encryptedMetaData: "SomeMetadata"
        )
    }
}
