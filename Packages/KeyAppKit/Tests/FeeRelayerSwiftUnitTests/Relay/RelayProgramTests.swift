import XCTest
@testable import FeeRelayerSwift
import SolanaSwift

final class RelayProgramTests: XCTestCase {
    let userAuthorityAddress: PublicKey = "6QuXb6mB6WmRASP2y8AavXh6aabBXEH5ZzrSH5xRrgSm"
    let feePayerAddress: PublicKey = "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu"
    let relayAccountAddress: PublicKey = "13DeafU3s4PoEUoDgyeNYZMqZWmgyN8fn3U5HrYxxXwQ"
    let userTemporaryWSOLAccountAddress: PublicKey = "FMRxGTeTANuERNfCW4zLBgTDDH4aMkHhPfzYGXVf27Rj"
    let transitTokenAccountAddress: PublicKey = "JhhACrqV4LhpZY7ogW9Gy2MRLVanXXFxyiW548dsjBp"
    let swapProgramIds: [PublicKey] = [
        "HGeQ9fjhqKHeaSJr9pWBYSG1UWx3X9Jdx8nXX2immPDU",
        "2Z2Pbn1bsqN4NSrf1JLC1JRGNchoCVwXqsfeF7zWYTnK"
    ]
    let swapAccounts: [PublicKey] = [
        "9zrZuvGCmvR5Kke6jv6Vr4YjsAN7UNaBF6sfX2uUpuFE",
        "3YAaP5VXsi89AmBmuf7Wi42V1rPSQTB33yym62U4RGvF"
    ]
    let swapAuthorities: [PublicKey] = [
        "DjVXmFGH9TK3bybDn2cztrSky4TaczSrjquce3G6rgZX",
        "3WqcT3GLHk8WEmPTriJuX9GskWjhXJGnH5XsYhMRogNJ"
    ]
    let swapTransferAuthority: PublicKey = "NY4z68djHpoNZvzTWNxxb1hMZy5weMyf9hf2wiL2nFk"
    let swapSourceAddresses: [PublicKey] = [
        "2v1o9vQ6T8Mtaf7VwvW3F82WU6yVXKatbTiyCXF5yXhj",
        "2HWPtmPQwukqppAkxMNzkz8YetFYCXVSCzyBCUHbukyP"
    ]
    let swapDestinationAddresses: [PublicKey] = [
        "6pNNcF513AbYmD358jMJGwGykbqaK9WYmvipsiS1MrnG",
        "2x5kSEGhsmkXyzJWUnaNE95az1ZfzBwAECGPXYHoo6As"
    ]
    let swapPoolTokenMints: [PublicKey] = [
        "6QScGEUjKqBwMcQ66KU4z5zGkYFY2Fhss3EbH1KUdVqi",
        "75cjTPrKw42sgU9uUNVb4sHDWDwvaeowYFFxf2otmwJE"
    ]
    let swapPoolFeeAccounts: [PublicKey] = [
        "9BKpfmJeVV1VrBGBZZR5buC6aLsTpFf7JxgWCnRW2WXk",
        "Agv4JisteCzLUYsBgEtnyEcbz2tG7duok7ebaGAwDpft"
    ]
    let amountIns: [UInt64] = [
        10000,
        50000
    ]
    let amountOuts: [UInt64] = [
        50000,
        30000
    ]

    func testConstants() throws {
        // id
        XCTAssertEqual(RelayProgram.id(network: .mainnetBeta), "12YKFL4mnZz6CBEGePrf293mEzueQM3h8VLPUJsKpGs9")
        XCTAssertEqual(RelayProgram.id(network: .devnet), "6xKJFyuM6UHCT8F5SBxnjGt6ZrZYjsVfnAnAeHPU775k")
        XCTAssertEqual(RelayProgram.id(network: .testnet), "6xKJFyuM6UHCT8F5SBxnjGt6ZrZYjsVfnAnAeHPU775k")
    }
    
    func testGetUserRelayAddress() throws {
        let relayAddress = try RelayProgram.getUserRelayAddress(
            user: userAuthorityAddress,
            network: .mainnetBeta
        )
        XCTAssertEqual(relayAddress, relayAccountAddress)
    }
    
    func testGetUserTemporaryWSOLAddress() throws {
        let address = try RelayProgram.getUserTemporaryWSOLAddress(
            user: userAuthorityAddress,
            network: .mainnetBeta
        )
        XCTAssertEqual(address, userTemporaryWSOLAccountAddress)
    }
    
    func testGetTransitTokenAccountAddress() throws {
        let address = try RelayProgram.getTransitTokenAccountAddress(
            user: userAuthorityAddress,
            transitTokenMint: .usdcMint,
            network: .mainnetBeta
        )
        XCTAssertEqual(address, transitTokenAccountAddress)
    }
    
    func testTopUpDirectSwapInstruction() throws {
        let userSourceTokenAccountAddress: PublicKey = "DMuFEzSiYAyWw5bDBaDSnksTUBghTAPZ7Ptn89fJZK9h"
        
        let instruction = try RelayProgram.topUpSwapInstruction(
            network: .mainnetBeta,
            topUpSwap: createRelayDirectSwapParams(index: 0),
            userAuthorityAddress: userAuthorityAddress,
            userSourceTokenAccountAddress: userSourceTokenAccountAddress,
            feePayerAddress: feePayerAddress
        )
        
        XCTAssertEqual(instruction.programId, RelayProgram.id(network: .mainnetBeta))
        XCTAssertEqual(instruction.data.toHexString(), "00102700000000000050c3000000000000")
        XCTAssertEqual(instruction.keys, [
            .init(publicKey: .wrappedSOLMint, isSigner: false, isWritable: false),
            .init(publicKey: feePayerAddress, isSigner: true, isWritable: true),
            .init(publicKey: userAuthorityAddress, isSigner: true, isWritable: false),
            .init(publicKey: relayAccountAddress, isSigner: false, isWritable: true),
            .init(publicKey: TokenProgram.id, isSigner: false, isWritable: false),
            .init(publicKey: swapProgramIds[0], isSigner: false, isWritable: false),
            .init(publicKey: swapAccounts[0], isSigner: false, isWritable: false),
            .init(publicKey: swapAuthorities[0], isSigner: false, isWritable: false),
            .init(publicKey: swapTransferAuthority, isSigner: true, isWritable: false),
            .init(publicKey: userSourceTokenAccountAddress, isSigner: false, isWritable: true),
            .init(publicKey: userTemporaryWSOLAccountAddress, isSigner: false, isWritable: true),
            .init(publicKey: swapSourceAddresses[0], isSigner: false, isWritable: true),
            .init(publicKey: swapDestinationAddresses[0], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolTokenMints[0], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolFeeAccounts[0], isSigner: false, isWritable: true),
            .init(publicKey: .sysvarRent, isSigner: false, isWritable: false),
            .init(publicKey: SystemProgram.id, isSigner: false, isWritable: false)
        ])
    }
    
    func testTopUpTransitiveSwapInstruction() throws {
        let userSourceTokenAccountAddress: PublicKey = "DMuFEzSiYAyWw5bDBaDSnksTUBghTAPZ7Ptn89fJZK9h"
        let transitTokenMint = PublicKey.usdcMint
        let instruction = try RelayProgram.topUpSwapInstruction(
            network: .mainnetBeta,
            topUpSwap: TransitiveSwapData(
                from: createRelayDirectSwapParams(index: 0),
                to: createRelayDirectSwapParams(index: 1),
                transitTokenMintPubkey: transitTokenMint.base58EncodedString,
                needsCreateTransitTokenAccount: false
            ),
            userAuthorityAddress: userAuthorityAddress,
            userSourceTokenAccountAddress: userSourceTokenAccountAddress,
            feePayerAddress: feePayerAddress
        )
        
        XCTAssertEqual(instruction.programId, RelayProgram.id(network: .mainnetBeta))
        XCTAssertEqual(instruction.data.toHexString(), "01102700000000000050c30000000000003075000000000000")
        XCTAssertEqual(instruction.keys, [
            .init(publicKey: .wrappedSOLMint, isSigner: false, isWritable: false),
            .init(publicKey: feePayerAddress, isSigner: true, isWritable: true),
            .init(publicKey: userAuthorityAddress, isSigner: true, isWritable: false),
            .init(publicKey: relayAccountAddress, isSigner: false, isWritable: true),
            .init(publicKey: TokenProgram.id, isSigner: false, isWritable: false),
            .init(publicKey: swapTransferAuthority, isSigner: true, isWritable: false),
            .init(publicKey: userSourceTokenAccountAddress, isSigner: false, isWritable: true),
            .init(publicKey: transitTokenAccountAddress, isSigner: false, isWritable: true),
            .init(publicKey: userTemporaryWSOLAccountAddress, isSigner: false, isWritable: true),
            .init(publicKey: swapProgramIds[0], isSigner: false, isWritable: false),
            .init(publicKey: swapAccounts[0], isSigner: false, isWritable: false),
            .init(publicKey: swapAuthorities[0], isSigner: false, isWritable: false),
            .init(publicKey: swapSourceAddresses[0], isSigner: false, isWritable: true),
            .init(publicKey: swapDestinationAddresses[0], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolTokenMints[0], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolFeeAccounts[0], isSigner: false, isWritable: true),
            .init(publicKey: swapProgramIds[1], isSigner: false, isWritable: false),
            .init(publicKey: swapAccounts[1], isSigner: false, isWritable: false),
            .init(publicKey: swapAuthorities[1], isSigner: false, isWritable: false),
            .init(publicKey: swapSourceAddresses[1], isSigner: false, isWritable: true),
            .init(publicKey: swapDestinationAddresses[1], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolTokenMints[1], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolFeeAccounts[1], isSigner: false, isWritable: true),
            .init(publicKey: .sysvarRent, isSigner: false, isWritable: false),
            .init(publicKey: SystemProgram.id, isSigner: false, isWritable: false)
        ])
    }
    
    func testTransferSOLInstruction() throws {
        let instruction = try RelayProgram.transferSolInstruction(
            userAuthorityAddress: userAuthorityAddress,
            recipient: feePayerAddress,
            lamports: 2039280, // expected fee
            network: .mainnetBeta
        )
        
        XCTAssertEqual(instruction.programId, RelayProgram.id(network: .mainnetBeta))
        XCTAssertEqual(instruction.data.toHexString(), "02f01d1f0000000000")
        XCTAssertEqual(instruction.keys, [
            .init(publicKey: userAuthorityAddress, isSigner: true, isWritable: false),
            .init(publicKey: try RelayProgram.getUserRelayAddress(user: userAuthorityAddress, network: .mainnetBeta), isSigner: false, isWritable: true),
            .init(publicKey: feePayerAddress, isSigner: false, isWritable: true),
            .init(publicKey: SystemProgram.id, isSigner: false, isWritable: false)
        ])
    }
    
    func testCreateTransitAccountInstruction() throws {
        let transitTokenAccount: PublicKey = "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3"
        let transitTokenMint: PublicKey = .usdcMint
        let instruction = try RelayProgram.createTransitTokenAccountInstruction(
            feePayer: feePayerAddress,
            userAuthority: userAuthorityAddress,
            transitTokenAccount: transitTokenAccount,
            transitTokenMint: transitTokenMint,
            network: .mainnetBeta
        )
        
        XCTAssertEqual(instruction.programId, RelayProgram.id(network: .mainnetBeta))
        XCTAssertEqual(instruction.data.toHexString(), "03")
        XCTAssertEqual(instruction.keys, [
            .init(publicKey: transitTokenAccount, isSigner: false, isWritable: true),
            .init(publicKey: .usdcMint, isSigner: false, isWritable: false),
            .init(publicKey: userAuthorityAddress, isSigner: true, isWritable: true),
            .init(publicKey: feePayerAddress, isSigner: true, isWritable: false),
            .init(publicKey: TokenProgram.id, isSigner: false, isWritable: false),
            .init(publicKey: .sysvarRent, isSigner: false, isWritable: false),
            .init(publicKey: SystemProgram.id, isSigner: false, isWritable: false)
        ])
    }
    
    func testCreateRelaySwapInstruction() throws {
        let sourceAddressPubkey: PublicKey = "9GQV3bQP9tv7m6XgGMaixxEeEdxtFhwgABw2cxCFZoch"
        let transitTokenAccount: PublicKey = "29TwF9mm2ZfrcjRiV3PCRQmgYzL95HJJhaUairYmWLJC"
        let destinationAddressPubkey: PublicKey = "2vouHuf5TJToiEfMT5pPtirjrs2iDm14yrq9wgMZkrdE"
        let transitTokenMint: PublicKey = "3H5XKkE9uVvxsdrFeN4BLLGCmohiQN6aZJVVcJiXQ4WC"
        let instruction = try RelayProgram.createRelaySwapInstruction(
            transitiveSwap: .init(
                from: createRelayDirectSwapParams(index: 0),
                to: createRelayDirectSwapParams(index: 1),
                transitTokenMintPubkey: transitTokenMint.base58EncodedString,
                needsCreateTransitTokenAccount: false
            ),
            userAuthorityAddressPubkey: userAuthorityAddress,
            sourceAddressPubkey: sourceAddressPubkey,
            transitTokenAccount: transitTokenAccount,
            destinationAddressPubkey: destinationAddressPubkey,
            feePayerPubkey: feePayerAddress,
            network: .mainnetBeta
        )
        
        XCTAssertEqual(instruction.programId, RelayProgram.id(network: .mainnetBeta))
        XCTAssertEqual(instruction.data.toHexString(), "04102700000000000050c30000000000003075000000000000")
        XCTAssertEqual(instruction.keys, [
            .init(publicKey: feePayerAddress, isSigner: true, isWritable: true),
            .init(publicKey: TokenProgram.id, isSigner: false, isWritable: false),
            .init(publicKey: swapTransferAuthority, isSigner: true, isWritable: false),
            .init(publicKey: sourceAddressPubkey, isSigner: false, isWritable: true),
            .init(publicKey: transitTokenAccount, isSigner: false, isWritable: true),
            .init(publicKey: destinationAddressPubkey, isSigner: false, isWritable: true),
            .init(publicKey: swapProgramIds[0], isSigner: false, isWritable: false),
            .init(publicKey: swapAccounts[0], isSigner: false, isWritable: false),
            .init(publicKey: swapAuthorities[0], isSigner: false, isWritable: false),
            .init(publicKey: swapSourceAddresses[0], isSigner: false, isWritable: true),
            .init(publicKey: swapDestinationAddresses[0], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolTokenMints[0], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolFeeAccounts[0], isSigner: false, isWritable: true),
            .init(publicKey: swapProgramIds[1], isSigner: false, isWritable: false),
            .init(publicKey: swapAccounts[1], isSigner: false, isWritable: false),
            .init(publicKey: swapAuthorities[1], isSigner: false, isWritable: false),
            .init(publicKey: swapSourceAddresses[1], isSigner: false, isWritable: true),
            .init(publicKey: swapDestinationAddresses[1], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolTokenMints[1], isSigner: false, isWritable: true),
            .init(publicKey: swapPoolFeeAccounts[1], isSigner: false, isWritable: true)
        ])
    }
    
    private func createRelayDirectSwapParams(index: Int) -> DirectSwapData {
        .init(
            programId: swapProgramIds[index].base58EncodedString,
            accountPubkey: swapAccounts[index].base58EncodedString,
            authorityPubkey: swapAuthorities[index].base58EncodedString,
            transferAuthorityPubkey: swapTransferAuthority.base58EncodedString,
            sourcePubkey: swapSourceAddresses[index].base58EncodedString,
            destinationPubkey: swapDestinationAddresses[index].base58EncodedString,
            poolTokenMintPubkey: swapPoolTokenMints[index].base58EncodedString,
            poolFeeAccountPubkey: swapPoolFeeAccounts[index].base58EncodedString,
            amountIn: amountIns[index],
            minimumAmountOut: amountOuts[index]
        )
    }
}
