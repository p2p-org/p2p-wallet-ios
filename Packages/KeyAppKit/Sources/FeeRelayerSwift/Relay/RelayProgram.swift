import Foundation
import SolanaSwift

public enum RelayProgram {
    // MARK: - Nested type

    public enum Index {
        static let topUpWithDirectSwap: UInt8 = 0
        static let topUpWithTransitiveSwap: UInt8 = 1
        static let transferSOL: UInt8 = 2
        static let createTransitToken: UInt8 = 3
        static let transitiveSwap: UInt8 = 4
    }
    
    // MARK: - Properties
    
    public static func id(network: Network) -> PublicKey {
        switch network {
        case .mainnetBeta:
            return "12YKFL4mnZz6CBEGePrf293mEzueQM3h8VLPUJsKpGs9"
        case .devnet:
            return "6xKJFyuM6UHCT8F5SBxnjGt6ZrZYjsVfnAnAeHPU775k"
        case .testnet:
            return "6xKJFyuM6UHCT8F5SBxnjGt6ZrZYjsVfnAnAeHPU775k" // unknown
        }
    }
    
    public static func getUserRelayAddress(
        user: PublicKey,
        network: Network
    ) throws -> PublicKey {
        try .findProgramAddress(seeds: [user.data, "relay".data(using: .utf8)!], programId: id(network: network)).0
    }
    
    public static func getUserTemporaryWSOLAddress(
        user: PublicKey,
        network: Network
    ) throws -> PublicKey {
        try .findProgramAddress(seeds: [user.data, "temporary_wsol".data(using: .utf8)!], programId: id(network: network)).0
    }
    
    public static func getTransitTokenAccountAddress(
        user: PublicKey,
        transitTokenMint: PublicKey,
        network: Network
    ) throws -> PublicKey {
        try .findProgramAddress(seeds: [user.data, transitTokenMint.data, "transit".data(using: .utf8)!], programId: id(network: network)).0
    }
    
    public static func topUpSwapInstruction(
        network: Network,
        topUpSwap: FeeRelayerRelaySwapType,
        userAuthorityAddress: PublicKey,
        userSourceTokenAccountAddress: PublicKey,
        feePayerAddress: PublicKey
    ) throws -> TransactionInstruction {
        let userRelayAddress = try getUserRelayAddress(user: userAuthorityAddress, network: network)
        let userTemporarilyWSOLAddress = try getUserTemporaryWSOLAddress(user: userAuthorityAddress, network: network)
        
        switch topUpSwap {
        case let swap as DirectSwapData:
            return topUpWithSPLSwapDirectInstruction(
                feePayer: feePayerAddress,
                userAuthority: userAuthorityAddress,
                userRelayAccount: userRelayAddress,
                userTransferAuthority: try PublicKey(string: swap.transferAuthorityPubkey),
                userSourceTokenAccount: userSourceTokenAccountAddress,
                userTemporaryWsolAccount: userTemporarilyWSOLAddress,
                swapProgramId: try PublicKey(string: swap.programId),
                swapAccount: try PublicKey(string: swap.accountPubkey),
                swapAuthority: try PublicKey(string: swap.authorityPubkey),
                swapSource: try PublicKey(string: swap.sourcePubkey),
                swapDestination: try PublicKey(string: swap.destinationPubkey),
                poolTokenMint: try PublicKey(string: swap.poolTokenMintPubkey),
                poolFeeAccount: try PublicKey(string: swap.poolFeeAccountPubkey),
                amountIn: swap.amountIn,
                minimumAmountOut: swap.minimumAmountOut,
                network: network
            )
        case let swap as TransitiveSwapData:
            return try topUpWithSPLSwapTransitiveInstruction(
                feePayer: feePayerAddress,
                userAuthority: userAuthorityAddress,
                userRelayAccount: userRelayAddress,
                userTransferAuthority: try PublicKey(string: swap.from.transferAuthorityPubkey),
                userSourceTokenAccount: userSourceTokenAccountAddress,
                userDestinationTokenAccount: userTemporarilyWSOLAddress,
                transitTokenMint: try PublicKey(string: swap.transitTokenMintPubkey),
                swapFromProgramId: try PublicKey(string: swap.from.programId),
                swapFromAccount: try PublicKey(string: swap.from.accountPubkey),
                swapFromAuthority: try PublicKey(string: swap.from.authorityPubkey),
                swapFromSource: try PublicKey(string: swap.from.sourcePubkey),
                swapFromDestination: try PublicKey(string: swap.from.destinationPubkey),
                swapFromPoolTokenMint: try PublicKey(string: swap.from.poolTokenMintPubkey),
                swapFromPoolFeeAccount: try PublicKey(string: swap.from.poolFeeAccountPubkey),
                swapToProgramId: try PublicKey(string: swap.to.programId),
                swapToAccount: try PublicKey(string: swap.to.accountPubkey),
                swapToAuthority: try PublicKey(string: swap.to.authorityPubkey),
                swapToSource: try PublicKey(string: swap.to.sourcePubkey),
                swapToDestination: try PublicKey(string: swap.to.destinationPubkey),
                swapToPoolTokenMint: try PublicKey(string: swap.to.poolTokenMintPubkey),
                swapToPoolFeeAccount: try PublicKey(string: swap.to.poolFeeAccountPubkey),
                amountIn: swap.from.amountIn,
                transitMinimumAmount: swap.from.minimumAmountOut,
                minimumAmountOut: swap.to.minimumAmountOut,
                network: network
            )
        default:
            fatalError("unsupported swap type")
        }
    }
    
    public static func transferSolInstruction(
        userAuthorityAddress: PublicKey,
        recipient: PublicKey,
        lamports: UInt64,
        network: Network
    ) throws -> TransactionInstruction {
        .init(
            keys: [
                .readonly(publicKey: userAuthorityAddress, isSigner: true),
                .writable(publicKey: try getUserRelayAddress(user: userAuthorityAddress, network: network), isSigner: false),
                .writable(publicKey: recipient, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false),
            ],
            programId: id(network: network),
            data: [
                Index.transferSOL,
                lamports
            ]
        )
    }
    
    public static func createTransitTokenAccountInstruction(
        feePayer: PublicKey,
        userAuthority: PublicKey,
        transitTokenAccount: PublicKey,
        transitTokenMint: PublicKey,
        network: Network
    ) throws -> TransactionInstruction {
        .init(
            keys: [
                .writable(publicKey: transitTokenAccount, isSigner: false),
                .readonly(publicKey: transitTokenMint, isSigner: false),
                .writable(publicKey: userAuthority, isSigner: true),
                .readonly(publicKey: feePayer, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: id(network: network),
            data: [Index.createTransitToken]
        )
    }
    
    public static func createRelaySwapInstruction(
        transitiveSwap: TransitiveSwapData,
        userAuthorityAddressPubkey: PublicKey,
        sourceAddressPubkey: PublicKey,
        transitTokenAccount: PublicKey,
        destinationAddressPubkey: PublicKey,
        feePayerPubkey: PublicKey,
        network: Network
    ) throws -> TransactionInstruction {
        let transferAuthorityPubkey = try PublicKey(string: transitiveSwap.from.transferAuthorityPubkey)
        let transitTokenMintPubkey = try PublicKey(string: transitiveSwap.transitTokenMintPubkey)
        let swapFromProgramId = try PublicKey(string: transitiveSwap.from.programId)
        let swapFromAccount = try PublicKey(string: transitiveSwap.from.accountPubkey)
        let swapFromAuthority = try PublicKey(string: transitiveSwap.from.authorityPubkey)
        let swapFromSource = try PublicKey(string: transitiveSwap.from.sourcePubkey)
        let swapFromDestination = try PublicKey(string: transitiveSwap.from.destinationPubkey)
        let swapFromTokenMint = try PublicKey(string: transitiveSwap.from.poolTokenMintPubkey)
        let swapFromPoolFeeAccount = try PublicKey(string: transitiveSwap.from.poolFeeAccountPubkey)
        let swapToProgramId = try PublicKey(string: transitiveSwap.to.programId)
        let swapToAccount = try PublicKey(string: transitiveSwap.to.accountPubkey)
        let swapToAuthority = try PublicKey(string: transitiveSwap.to.authorityPubkey)
        let swapToSource = try PublicKey(string: transitiveSwap.to.sourcePubkey)
        let swapToDestination = try PublicKey(string: transitiveSwap.to.destinationPubkey)
        let swapToPoolTokenMint = try PublicKey(string: transitiveSwap.to.poolTokenMintPubkey)
        let swapToPoolFeeAccount = try PublicKey(string: transitiveSwap.to.poolFeeAccountPubkey)
        let amountIn = transitiveSwap.from.amountIn
        let transitMinimumAmount = transitiveSwap.from.minimumAmountOut
        let minimumAmountOut = transitiveSwap.to.minimumAmountOut
        
        
        return try splSwapTransitiveInstruction(
            feePayer: feePayerPubkey,
            userAuthority: userAuthorityAddressPubkey,
            userTransferAuthority: transferAuthorityPubkey,
            userSourceTokenAccount: sourceAddressPubkey,
            userTransitTokenAccount: transitTokenAccount,
            userDestinationTokenAccount: destinationAddressPubkey,
            transitTokenMint: transitTokenMintPubkey,
            swapFromProgramId: swapFromProgramId,
            swapFromAccount: swapFromAccount,
            swapFromAuthority: swapFromAuthority,
            swapFromSource: swapFromSource,
            swapFromDestination: swapFromDestination,
            swapFromPoolTokenMint: swapFromTokenMint,
            swapFromPoolFeeAccount: swapFromPoolFeeAccount,
            swapToProgramId: swapToProgramId,
            swapToAccount: swapToAccount,
            swapToAuthority: swapToAuthority,
            swapToSource: swapToSource,
            swapToDestination: swapToDestination,
            swapToPoolTokenMint: swapToPoolTokenMint,
            swapToPoolFeeAccount: swapToPoolFeeAccount,
            amountIn: amountIn,
            transitMinimumAmount: transitMinimumAmount,
            minimumAmountOut: minimumAmountOut,
            network: network
        )
    }
    
    // MARK: - Helpers
    private static func topUpWithSPLSwapDirectInstruction(
        feePayer: PublicKey,
        userAuthority: PublicKey,
        userRelayAccount: PublicKey,
        userTransferAuthority: PublicKey,
        userSourceTokenAccount: PublicKey,
        userTemporaryWsolAccount: PublicKey,
        swapProgramId: PublicKey,
        swapAccount: PublicKey,
        swapAuthority: PublicKey,
        swapSource: PublicKey,
        swapDestination: PublicKey,
        poolTokenMint: PublicKey,
        poolFeeAccount: PublicKey,
        amountIn: UInt64,
        minimumAmountOut: UInt64,
        network: Network
    ) -> TransactionInstruction {
        .init(
            keys: [
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .writable(publicKey: feePayer, isSigner: true),
                .readonly(publicKey: userAuthority, isSigner: true),
                .writable(publicKey: userRelayAccount, isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: swapProgramId, isSigner: false),
                .readonly(publicKey: swapAccount, isSigner: false),
                .readonly(publicKey: swapAuthority, isSigner: false),
                .readonly(publicKey: userTransferAuthority, isSigner: true),
                .writable(publicKey: userSourceTokenAccount, isSigner: false),
                .writable(publicKey: userTemporaryWsolAccount, isSigner: false),
                .writable(publicKey: swapSource, isSigner: false),
                .writable(publicKey: swapDestination, isSigner: false),
                .writable(publicKey: poolTokenMint, isSigner: false),
                .writable(publicKey: poolFeeAccount, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: id(network: network),
            data: [
                Index.topUpWithDirectSwap,
                amountIn,
                minimumAmountOut
            ]
        )
    }
    
    private static func topUpWithSPLSwapTransitiveInstruction(
        feePayer: PublicKey,
        userAuthority: PublicKey,
        userRelayAccount: PublicKey,
        userTransferAuthority: PublicKey,
        userSourceTokenAccount: PublicKey,
        userDestinationTokenAccount: PublicKey,
        transitTokenMint: PublicKey,
        swapFromProgramId: PublicKey,
        swapFromAccount: PublicKey,
        swapFromAuthority: PublicKey,
        swapFromSource: PublicKey,
        swapFromDestination: PublicKey,
        swapFromPoolTokenMint: PublicKey,
        swapFromPoolFeeAccount: PublicKey,
        swapToProgramId: PublicKey,
        swapToAccount: PublicKey,
        swapToAuthority: PublicKey,
        swapToSource: PublicKey,
        swapToDestination: PublicKey,
        swapToPoolTokenMint: PublicKey,
        swapToPoolFeeAccount: PublicKey,
        amountIn: UInt64,
        transitMinimumAmount: UInt64,
        minimumAmountOut: UInt64,
        network: Network
    ) throws -> TransactionInstruction {
        .init(
            keys: [
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .writable(publicKey: feePayer, isSigner: true),
                .readonly(publicKey: userAuthority, isSigner: true),
                .writable(publicKey: userRelayAccount, isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: userTransferAuthority, isSigner: true),
                .writable(publicKey: userSourceTokenAccount, isSigner: false),
                .writable(publicKey: try getTransitTokenAccountAddress(user: userAuthority, transitTokenMint: transitTokenMint, network: network), isSigner: false),
                .writable(publicKey: userDestinationTokenAccount, isSigner: false),
                .readonly(publicKey: swapFromProgramId, isSigner: false),
                .readonly(publicKey: swapFromAccount, isSigner: false),
                .readonly(publicKey: swapFromAuthority, isSigner: false),
                .writable(publicKey: swapFromSource, isSigner: false),
                .writable(publicKey: swapFromDestination, isSigner: false),
                .writable(publicKey: swapFromPoolTokenMint, isSigner: false),
                .writable(publicKey: swapFromPoolFeeAccount, isSigner: false),
                .readonly(publicKey: swapToProgramId, isSigner: false),
                .readonly(publicKey: swapToAccount, isSigner: false),
                .readonly(publicKey: swapToAuthority, isSigner: false),
                .writable(publicKey: swapToSource, isSigner: false),
                .writable(publicKey: swapToDestination, isSigner: false),
                .writable(publicKey: swapToPoolTokenMint, isSigner: false),
                .writable(publicKey: swapToPoolFeeAccount, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: id(network: network),
            data: [
                Index.topUpWithTransitiveSwap,
                amountIn,
                transitMinimumAmount,
                minimumAmountOut
            ]
        )
    }
    
    private static func splSwapTransitiveInstruction(
        feePayer: PublicKey,
        userAuthority: PublicKey,
        userTransferAuthority: PublicKey,
        userSourceTokenAccount: PublicKey,
        userTransitTokenAccount: PublicKey,
        userDestinationTokenAccount: PublicKey,
        transitTokenMint: PublicKey,
        swapFromProgramId: PublicKey,
        swapFromAccount: PublicKey,
        swapFromAuthority: PublicKey,
        swapFromSource: PublicKey,
        swapFromDestination: PublicKey,
        swapFromPoolTokenMint: PublicKey,
        swapFromPoolFeeAccount: PublicKey,
        swapToProgramId: PublicKey,
        swapToAccount: PublicKey,
        swapToAuthority: PublicKey,
        swapToSource: PublicKey,
        swapToDestination: PublicKey,
        swapToPoolTokenMint: PublicKey,
        swapToPoolFeeAccount: PublicKey,
        amountIn: UInt64,
        transitMinimumAmount: UInt64,
        minimumAmountOut: UInt64,
        network: Network
    ) throws -> TransactionInstruction {
        .init(
            keys: [
                .writable(publicKey: feePayer, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: userTransferAuthority, isSigner: true),
                .writable(publicKey: userSourceTokenAccount, isSigner: false),
                .writable(publicKey: userTransitTokenAccount, isSigner: false),
                .writable(publicKey: userDestinationTokenAccount, isSigner: false),
                .readonly(publicKey: swapFromProgramId, isSigner: false),
                .readonly(publicKey: swapFromAccount, isSigner: false),
                .readonly(publicKey: swapFromAuthority, isSigner: false),
                .writable(publicKey: swapFromSource, isSigner: false),
                .writable(publicKey: swapFromDestination, isSigner: false),
                .writable(publicKey: swapFromPoolTokenMint, isSigner: false),
                .writable(publicKey: swapFromPoolFeeAccount, isSigner: false),
                .readonly(publicKey: swapToProgramId, isSigner: false),
                .readonly(publicKey: swapToAccount, isSigner: false),
                .readonly(publicKey: swapToAuthority, isSigner: false),
                .writable(publicKey: swapToSource, isSigner: false),
                .writable(publicKey: swapToDestination, isSigner: false),
                .writable(publicKey: swapToPoolTokenMint, isSigner: false),
                .writable(publicKey: swapToPoolFeeAccount, isSigner: false),
            ],
            programId: id(network: network),
            data: [
                Index.transitiveSwap,
                amountIn,
                transitMinimumAmount,
                minimumAmountOut
            ]
        )
    }
}
