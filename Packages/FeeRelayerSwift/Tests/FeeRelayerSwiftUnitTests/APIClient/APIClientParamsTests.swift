import Foundation
import XCTest
@testable import FeeRelayerSwift
import SolanaSwift

class APIClientParamsTests: XCTestCase {
    func testEncodingTopUpWithDirectSwapParams() throws {
        let params = TopUpWithSwapParams(
            userSourceTokenAccount: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
            sourceTokenMint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            userAuthority: "6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D",
            topUpSwap: .init(createRelayDirectSwapParams(index: 0)),
            feeAmount: 500000,
            signatures: fakeSignature,
            blockhash: "FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S",
            deviceType: .iOS,
            buildNumber: "1.0.0",
            environment: .dev
        )
        
        let data = try JSONEncoder().encode(params)
        let string = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(string, #"{"user_authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","top_up_swap":{"Spl":{"pool_fee_account_pubkey":"EDuiPgd4PuCXe9h2YieMbH7uUMeB4pgeWnP5hfcPvxu3","account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","destination_pubkey":"CRh1jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX","amount_in":500000,"source_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","transfer_authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","minimum_amount_out":500000,"authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","program_id":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","pool_token_mint_pubkey":"3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC"}},"user_source_token_account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","signatures":{"user_authority_signature":"3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd","transfer_authority_signature":"3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd"},"blockhash":"FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S","fee_amount":500000,"source_token_mint_pubkey":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","info":{"build":"1.0.0","currency":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","environment":"dev","operation_type":"TopUp","device_type":"Ios"}}"#)
    }
    
    func testEncodingTopUpWithTransitiveSwapParams() throws {
        let params = TopUpWithSwapParams(
            userSourceTokenAccount: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
            sourceTokenMint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            userAuthority: "6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D",
            topUpSwap: .init(TransitiveSwapData(
                from: createRelayDirectSwapParams(index: 0),
                to: createRelayDirectSwapParams(index: 1),
                transitTokenMintPubkey: "3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC",
                needsCreateTransitTokenAccount: false
            )),
            feeAmount: 500000,
            signatures: fakeSignature,
            blockhash: "FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S",
            deviceType: .iOS,
            buildNumber: "1.0.0",
            environment: .dev
        )
        
        let data = try JSONEncoder().encode(params)
        let string = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(string, #"{"user_authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","top_up_swap":{"SplTransitive":{"to":{"pool_fee_account_pubkey":"EDuiPgd4PuCXe9h2YieMbH7uUMeB4pgeWnP5hfcPvxu3","account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","destination_pubkey":"CRh2jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX","amount_in":500000,"source_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","transfer_authority_pubkey":"6Aj2GVxoCiEhhYTk9rNySg2QTgvtqSzR229KynihWH3D","minimum_amount_out":500000,"authority_pubkey":"6Aj2GVxoCiEhhYTk9rNySg2QTgvtqSzR229KynihWH3D","program_id":"6Aj2GVxoCiEhhYTk9rNySg2QTgvtqSzR229KynihWH3D","pool_token_mint_pubkey":"3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC"},"needs_create_transit_token_account":false,"transit_token_mint_pubkey":"3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC","from":{"pool_fee_account_pubkey":"EDuiPgd4PuCXe9h2YieMbH7uUMeB4pgeWnP5hfcPvxu3","account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","destination_pubkey":"CRh1jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX","amount_in":500000,"source_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","transfer_authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","minimum_amount_out":500000,"authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","program_id":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","pool_token_mint_pubkey":"3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC"}}},"user_source_token_account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","signatures":{"user_authority_signature":"3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd","transfer_authority_signature":"3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd"},"blockhash":"FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S","fee_amount":500000,"source_token_mint_pubkey":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","info":{"build":"1.0.0","currency":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","environment":"dev","operation_type":"TopUp","device_type":"Ios"}}"#)
    }
    
    func testEncodingSwapWithDirectSwapParams() throws {
        let params = SwapParams(
            userSourceTokenAccountPubkey: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
            userDestinationPubkey: "6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D",
            userDestinationAccountOwner: nil,
            sourceTokenMintPubkey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            destinationTokenMintPubkey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            userAuthorityPubkey: "6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D",
            userSwap: .init(createRelayDirectSwapParams(index: 0)),
            feeAmount: 500000,
            signatures: fakeSignature,
            blockhash: "FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S"
        )
        
        let data = try JSONEncoder().encode(params)
        let string = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(string, #"{"destination_token_mint_pubkey":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","user_authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","user_source_token_account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","user_swap":{"Spl":{"pool_fee_account_pubkey":"EDuiPgd4PuCXe9h2YieMbH7uUMeB4pgeWnP5hfcPvxu3","account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","destination_pubkey":"CRh1jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX","amount_in":500000,"source_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","transfer_authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","minimum_amount_out":500000,"authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","program_id":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","pool_token_mint_pubkey":"3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC"}},"signatures":{"user_authority_signature":"3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd","transfer_authority_signature":"3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd"},"blockhash":"FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S","user_destination_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","source_token_mint_pubkey":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","fee_amount":500000}"#)
    }
    
    func testEncodingSwapWithTransitiveSwapParams() throws {
        let params = SwapParams(
            userSourceTokenAccountPubkey: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
            userDestinationPubkey: "CRh1jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX",
            userDestinationAccountOwner: "CRh1jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX",
            sourceTokenMintPubkey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            destinationTokenMintPubkey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            userAuthorityPubkey: "6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D",
            userSwap: .init(TransitiveSwapData(
                from: createRelayDirectSwapParams(index: 0),
                to: createRelayDirectSwapParams(index: 1),
                transitTokenMintPubkey: "3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC",
                needsCreateTransitTokenAccount: false
            )),
            feeAmount: 50000,
            signatures: fakeSignature,
            blockhash: "FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S"
        )
        
        let data = try JSONEncoder().encode(params)
        let string = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(string, #"{"destination_token_mint_pubkey":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","user_authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","fee_amount":50000,"user_source_token_account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","user_swap":{"SplTransitive":{"to":{"pool_fee_account_pubkey":"EDuiPgd4PuCXe9h2YieMbH7uUMeB4pgeWnP5hfcPvxu3","account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","destination_pubkey":"CRh2jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX","amount_in":500000,"source_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","transfer_authority_pubkey":"6Aj2GVxoCiEhhYTk9rNySg2QTgvtqSzR229KynihWH3D","minimum_amount_out":500000,"authority_pubkey":"6Aj2GVxoCiEhhYTk9rNySg2QTgvtqSzR229KynihWH3D","program_id":"6Aj2GVxoCiEhhYTk9rNySg2QTgvtqSzR229KynihWH3D","pool_token_mint_pubkey":"3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC"},"needs_create_transit_token_account":false,"transit_token_mint_pubkey":"3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC","from":{"pool_fee_account_pubkey":"EDuiPgd4PuCXe9h2YieMbH7uUMeB4pgeWnP5hfcPvxu3","account_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","destination_pubkey":"CRh1jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX","amount_in":500000,"source_pubkey":"3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3","transfer_authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","minimum_amount_out":500000,"authority_pubkey":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","program_id":"6Aj1GVxoCiEhhYTk9rNySg2QTgvtqSzR119KynihWH3D","pool_token_mint_pubkey":"3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC"}}},"signatures":{"user_authority_signature":"3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd","transfer_authority_signature":"3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd"},"blockhash":"FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S","user_destination_pubkey":"CRh1jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX","source_token_mint_pubkey":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","user_destination_account_owner":"CRh1jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX"}"#)
    }
    
    func testEncodingRelayTransactionParams() async throws {
        let phrase = "assume legend squirrel drastic immense ribbon reduce thrive page uncover vehicle cart right tank wheel whisper ride pet wall august link wheel moment enlist"
        
        let signer = try await Account(phrase: phrase.components(separatedBy: " "), network: .mainnetBeta)
        
        var transaction = Transaction()
        transaction.instructions = [
            SystemProgram.transferInstruction(
                from: signer.publicKey,
                to: "6Aj2GVxoCiEhhYTk9rNySg2QTgvtqSzR229KynihWH3D",
                lamports: 50000
            )
        ]
        transaction.feePayer = signer.publicKey
        transaction.recentBlockhash = "FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S"
        
        try transaction.sign(signers: [signer])
        
        let preparedTransaction = PreparedTransaction(
            transaction: transaction,
            signers: [signer],
            expectedFee: .init(transaction: 0, accountBalances: 0)
        )
        
        let params = try RelayTransactionParam(
            preparedTransaction: preparedTransaction,
            statsInfo: .init(
                operationType: .transfer,
                deviceType: .iOS,
                currency: "SOL",
                build: "2.0.0",
                environment: .dev
            )
        )
        
        let data = try JSONEncoder().encode(params)
        let string = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(string, #"{"signatures":{"0":"5uvRMZRq2HopDZQx3pwgAn6WEUr1ETECm565EdyG5xwXtowpnetxdJzzSo6NEF1LffzwNMRaCByUhArMv23u3SJN"},"pubkeys":["Gd24j8rZNEZYQnnDEHrzzNW5KnyP9JCe4wpC2otNWt7z","6Aj2GVxoCiEhhYTk9rNySg2QTgvtqSzR229KynihWH3D","11111111111111111111111111111111"],"info":{"build":"2.0.0","currency":"SOL","environment":"dev","operation_type":"Transfer","device_type":"Ios"},"instructions":[{"accounts":[{"is_signer":true,"is_writable":true,"pubkey":0},{"is_signer":false,"is_writable":true,"pubkey":1}],"data":[2,0,0,0,80,195,0,0,0,0,0,0],"program_id":2}],"blockhash":"FyGp8WQvMAMiXs1E3YHRPhQ9KeNquTGu9NdnnKudrF7S"}"#)
    }
}

// MARK: - Helpers
private func createRelayDirectSwapParams(index: Int) -> DirectSwapData {
    .init(
        programId: "6Aj\(index+1)GVxoCiEhhYTk9rNySg2QTgvtqSzR\(index+1)\(index+1)9KynihWH3D",
        accountPubkey: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
        authorityPubkey: "6Aj\(index+1)GVxoCiEhhYTk9rNySg2QTgvtqSzR\(index+1)\(index+1)9KynihWH3D",
        transferAuthorityPubkey: "6Aj\(index+1)GVxoCiEhhYTk9rNySg2QTgvtqSzR\(index+1)\(index+1)9KynihWH3D",
        sourcePubkey: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
        destinationPubkey: "CRh\(index+1)jz9Ahs4ZLdTDtsQqtTh8UWFDFre6NtvFTWXQspeX",
        poolTokenMintPubkey: "3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC",
        poolFeeAccountPubkey: "EDuiPgd4PuCXe9h2YieMbH7uUMeB4pgeWnP5hfcPvxu3",
        amountIn: 500000,
        minimumAmountOut: 500000
    )
}

private var fakeSignature: SwapTransactionSignatures {
    .init(
        userAuthoritySignature: "3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd",
        transferAuthoritySignature: "3rR2np1ZtgNa9QCnhGCybFXEiHKref7CAvpMA4DEh8yJ8gCF5oXKGzJZ8TEWTzUTQGZNm83CQyjyiSo2VHcQWXJd"
    )
}
