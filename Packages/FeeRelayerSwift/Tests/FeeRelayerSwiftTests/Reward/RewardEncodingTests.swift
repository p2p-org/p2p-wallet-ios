//import Foundation
//import XCTest
//import FeeRelayerSwift
//
//class RewardEncodingTests: XCTestCase {
//    func testEncodingTransferSOLParams() throws {
//        let params = FeeRelayer.Reward.TransferSolParams(
//            sender: "JAmdLePQthdecE7rbgVbz1WUuCT3Q2g74vPbiQWSLxiH",
//            recipient: "4VsigVU3tx27Z68jis3Sxvxf2E3rUJKWy77G2xjYVqRa",
//            amount: 5000000000,
//            signature: "4pDHg6HXrXZ3MdAi7NeJW1LGcc9H83QaXZZXbsiFUhv3S14puroN695ukV4DUvSGq1GUug2oPBLwqG8t8547EXgy",
//            blockhash: "2zSkac7x52jjdD18zdDZfKDZpcmrKMq3RXodcN5G7MEx"
//        )
//
//        let data = try JSONEncoder().encode(params)
//        let string = String(data: data, encoding: .utf8)
//        XCTAssertEqual(string, #"{"sender_pubkey":"JAmdLePQthdecE7rbgVbz1WUuCT3Q2g74vPbiQWSLxiH","signature":"4pDHg6HXrXZ3MdAi7NeJW1LGcc9H83QaXZZXbsiFUhv3S14puroN695ukV4DUvSGq1GUug2oPBLwqG8t8547EXgy","lamports":5000000000,"recipient_pubkey":"4VsigVU3tx27Z68jis3Sxvxf2E3rUJKWy77G2xjYVqRa","blockhash":"2zSkac7x52jjdD18zdDZfKDZpcmrKMq3RXodcN5G7MEx"}"#)
//    }
//
//    func testEncodingTransferSPLTokenParams() throws {
//        let params = FeeRelayer.Reward.TransferSPLTokenParams(
//            sender: "DruRdCUMQvZQLRPHPYnmBHtWabfDZqBGsdFR7RaipKQR",
//            recipient: "v7dovhZiQJrAho3gMdgBjWFLGNTtwfra2on2fMEKFWC",
//            mintAddress: "AYemet2EiYqHUMGmrwwWx5Fhi8oM5nHmmgYJnnU9wnt8",
//            authority: "9JVy3p9UZnXkho62drSdJ9nanUx5ykRYuyskTYrP6VDV",
//            amount: 10000,
//            decimals: 3,
//            signature: "3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd",
//            blockhash: "FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S"
//        )
//
//        let data = try JSONEncoder().encode(params)
//        let string = String(data: data, encoding: .utf8)
//        XCTAssertEqual(string, #"{"amount":10000,"sender_token_account_pubkey":"DruRdCUMQvZQLRPHPYnmBHtWabfDZqBGsdFR7RaipKQR","token_mint_pubkey":"AYemet2EiYqHUMGmrwwWx5Fhi8oM5nHmmgYJnnU9wnt8","decimals":3,"signature":"3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd","recipient_pubkey":"v7dovhZiQJrAho3gMdgBjWFLGNTtwfra2on2fMEKFWC","blockhash":"FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S","authority_pubkey":"9JVy3p9UZnXkho62drSdJ9nanUx5ykRYuyskTYrP6VDV"}"#)
//    }
//}
