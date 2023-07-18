//
//  CheckSwapDataTests.swift
//  
//
//  Created by Chung Tran on 06/11/2022.
//

import XCTest
@testable import OrcaSwapSwift
@testable import FeeRelayerSwift
import SolanaSwift

final class CheckSwapDataTests: XCTestCase {
    var swapTransactionBuilder: SwapTransactionBuilderImpl!
    
    override func setUp() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
    }
    
    override func tearDown() async throws {
        swapTransactionBuilder = nil
    }
    
    func testCheckDirectSwapData() async throws {
        // BTC -> ETH
        let swapData = DirectSwapData(
            programId: PublicKey.deprecatedSwapProgramId.base58EncodedString,
            accountPubkey: Pool.btcETH.account,
            authorityPubkey: Pool.btcETH.authority,
            transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
            sourcePubkey: Pool.btcETH.tokenAccountA,
            destinationPubkey: Pool.btcETH.tokenAccountB,
            poolTokenMintPubkey: Pool.btcETH.poolTokenMint,
            poolFeeAccountPubkey: Pool.btcETH.feeAccount,
            amountIn: 14,
            minimumAmountOut: 171
        )
        
        var env = SwapTransactionBuilderOutput(
            userSource: .btcAssociatedAddress,
            userDestinationTokenAccountAddress: .ethAssociatedAddress
        )
        
        try swapTransactionBuilder.checkSwapData(
            owner: .owner,
            poolsPair: [.btcETH],
            env: &env,
            swapData: .init(swapData: swapData, transferAuthorityAccount: nil)
        )
        
        let swapInstruction = env.instructions[0]
        
        XCTAssertEqual(swapInstruction.keys[0], .readonly(publicKey: Pool.btcETH.account.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[1], .readonly(publicKey: Pool.btcETH.authority.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[2], .readonly(publicKey: .owner, isSigner: true))
        XCTAssertEqual(swapInstruction.keys[3], .writable(publicKey: "4Vfs3NZ1Bo8agrfBJhMFdesso8tBWyUZAPBGMoWHuNRU", isSigner: false))
        XCTAssertEqual(swapInstruction.keys[4], .writable(publicKey: Pool.btcETH.tokenAccountA.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[5], .writable(publicKey: Pool.btcETH.tokenAccountB.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[6], .writable(publicKey: .ethAssociatedAddress, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[7], .writable(publicKey: Pool.btcETH.poolTokenMint.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[8], .writable(publicKey: Pool.btcETH.feeAccount.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[9], .readonly(publicKey: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", isSigner: false))
        
        XCTAssertEqual(swapInstruction.programId, .deprecatedSwapProgramId)
        XCTAssertEqual(swapInstruction.data, [UInt8]([1, 14, 0, 0, 0, 0, 0, 0, 0, 171, 0, 0, 0, 0, 0, 0, 0]))
    }
    
    func testCheckTransitiveSwapData() async throws {
        // SOL -> BTC -> ETH
        let needsCreateTransitTokenAccount = true
        let userSource = try await Account(network: .mainnetBeta).publicKey
        
        let swapData = TransitiveSwapData(
            from: .init(
                programId: PublicKey.swapProgramId.base58EncodedString,
                accountPubkey: Pool.solBTC.account,
                authorityPubkey: Pool.solBTC.authority,
                transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                sourcePubkey: Pool.solBTC.tokenAccountA,
                destinationPubkey: Pool.solBTC.tokenAccountB,
                poolTokenMintPubkey: Pool.solBTC.poolTokenMint,
                poolFeeAccountPubkey: Pool.solBTC.feeAccount,
                amountIn: 10000000,
                minimumAmountOut: 14
            ),
            to: DirectSwapData(
                programId: PublicKey.deprecatedSwapProgramId.base58EncodedString,
                accountPubkey: Pool.btcETH.account,
                authorityPubkey: Pool.btcETH.authority,
                transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                sourcePubkey: Pool.btcETH.tokenAccountA,
                destinationPubkey: Pool.btcETH.tokenAccountB,
                poolTokenMintPubkey: Pool.btcETH.poolTokenMint,
                poolFeeAccountPubkey: Pool.btcETH.feeAccount,
                amountIn: 14,
                minimumAmountOut: 171
            ),
            transitTokenMintPubkey: PublicKey.btcMint.base58EncodedString,
            needsCreateTransitTokenAccount: needsCreateTransitTokenAccount
        )
        
        var env = SwapTransactionBuilderOutput(
            userSource: userSource,
            needsCreateTransitTokenAccount: needsCreateTransitTokenAccount,
            userDestinationTokenAccountAddress: .ethAssociatedAddress
        )
        
        try swapTransactionBuilder.checkSwapData(
            owner: .owner,
            poolsPair: [.btcETH],
            env: &env,
            swapData: .init(swapData: swapData, transferAuthorityAccount: nil)
        )
        
        XCTAssertEqual(env.instructions.count, needsCreateTransitTokenAccount ? 2: 1)
        
        var swapInstruction = env.instructions[0]
        
        if needsCreateTransitTokenAccount {
            let createTransitTokenAccountInstruction = env.instructions[0]
            swapInstruction = env.instructions[1]
            
            // check create transit token account
            XCTAssertEqual(createTransitTokenAccountInstruction.keys[0], .writable(publicKey: .btcTransitTokenAccountAddress, isSigner: false))
            XCTAssertEqual(createTransitTokenAccountInstruction.keys[1], .readonly(publicKey: .btcMint, isSigner: false))
            XCTAssertEqual(createTransitTokenAccountInstruction.keys[2], .writable(publicKey: .owner, isSigner: true))
            XCTAssertEqual(createTransitTokenAccountInstruction.keys[3], .readonly(publicKey: .feePayerAddress, isSigner: true))
            XCTAssertEqual(createTransitTokenAccountInstruction.keys[4], .readonly(publicKey: TokenProgram.id, isSigner: false))
            XCTAssertEqual(createTransitTokenAccountInstruction.keys[5], .readonly(publicKey: .sysvarRent, isSigner: false))
            XCTAssertEqual(createTransitTokenAccountInstruction.keys[6], .readonly(publicKey: SystemProgram.id, isSigner: false))
            
            XCTAssertEqual(createTransitTokenAccountInstruction.programId, RelayProgram.id(network: .mainnetBeta))
            XCTAssertEqual(createTransitTokenAccountInstruction.data, [UInt8]([3]))
        }
        
        // check swap instructions
        XCTAssertEqual(swapInstruction.keys[0], .writable(publicKey: .feePayerAddress, isSigner: true))
        XCTAssertEqual(swapInstruction.keys[1], .readonly(publicKey: TokenProgram.id, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[2], .readonly(publicKey: .owner, isSigner: true))
        XCTAssertEqual(swapInstruction.keys[3], .writable(publicKey: userSource, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[4], .writable(publicKey: .btcTransitTokenAccountAddress, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[5], .writable(publicKey: .ethAssociatedAddress, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[6], .readonly(publicKey: .swapProgramId, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[7], .readonly(publicKey: Pool.solBTC.account.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[8], .readonly(publicKey: try Pool.solBTC.authority.toPublicKey(), isSigner: false))
        XCTAssertEqual(swapInstruction.keys[9], .writable(publicKey: Pool.solBTC.tokenAccountA.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[10], .writable(publicKey: Pool.solBTC.tokenAccountB.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[11], .writable(publicKey: Pool.solBTC.poolTokenMint.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[12], .writable(publicKey: Pool.solBTC.feeAccount.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[13], .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[14], .readonly(publicKey: Pool.btcETH.account.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[15], .readonly(publicKey: Pool.btcETH.authority.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[16], .writable(publicKey: Pool.btcETH.tokenAccountA.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[17], .writable(publicKey: Pool.btcETH.tokenAccountB.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[18], .writable(publicKey: Pool.btcETH.poolTokenMint.publicKey, isSigner: false))
        XCTAssertEqual(swapInstruction.keys[19], .writable(publicKey: Pool.btcETH.feeAccount.publicKey, isSigner: false))

        XCTAssertEqual(swapInstruction.programId, "12YKFL4mnZz6CBEGePrf293mEzueQM3h8VLPUJsKpGs9")
        XCTAssertEqual(swapInstruction.data, [UInt8]([4, 128, 150, 152, 0, 0, 0, 0, 0, 14, 0, 0, 0, 0, 0, 0, 0, 171, 0, 0, 0, 0, 0, 0, 0]))
    }
}
