import Foundation
import OrcaSwapSwift
import SolanaSwift

extension SwapTransactionBuilderImpl {
    func checkSwapData(
        owner: PublicKey,
        poolsPair: PoolsPair,
        env: inout SwapTransactionBuilderOutput,
        swapData: SwapData
    ) throws {
        let userTransferAuthority = swapData.transferAuthorityAccount?.publicKey
        switch swapData.swapData {
        case let swap as DirectSwapData:
            guard let pool = poolsPair.first else { throw FeeRelayerError.swapPoolsNotFound }

            // approve
            if let userTransferAuthority = userTransferAuthority {
                env.instructions.append(
                    TokenProgram.approveInstruction(
                        account: env.userSource!,
                        delegate: userTransferAuthority,
                        owner: owner,
                        multiSigners: [],
                        amount: swap.amountIn
                    )
                )
            }

            // swap
            try env.instructions.append(
                pool.createSwapInstruction(
                    userTransferAuthorityPubkey: userTransferAuthority ?? owner,
                    sourceTokenAddress: env.userSource!,
                    destinationTokenAddress: env.userDestinationTokenAccountAddress!,
                    amountIn: swap.amountIn,
                    minAmountOut: swap.minimumAmountOut
                )
            )
        case let swap as TransitiveSwapData:
            // approve
            if let userTransferAuthority = userTransferAuthority {
                env.instructions.append(
                    TokenProgram.approveInstruction(
                        account: env.userSource!,
                        delegate: userTransferAuthority,
                        owner: owner,
                        multiSigners: [],
                        amount: swap.from.amountIn
                    )
                )
            }

            // get transit token info
            let transitTokenMint = try PublicKey(string: swap.transitTokenMintPubkey)
            let transitTokenAccountAddress = try RelayProgram.getTransitTokenAccountAddress(
                user: owner,
                transitTokenMint: transitTokenMint,
                network: network
            )

            // create transit token account if needed
            if env.needsCreateTransitTokenAccount == true {
                try env.instructions.append(
                    RelayProgram.createTransitTokenAccountInstruction(
                        feePayer: feePayerAddress,
                        userAuthority: owner,
                        transitTokenAccount: transitTokenAccountAddress,
                        transitTokenMint: transitTokenMint,
                        network: network
                    )
                )
            }

            // relay swap
            try env.instructions.append(
                RelayProgram.createRelaySwapInstruction(
                    transitiveSwap: swap,
                    userAuthorityAddressPubkey: owner,
                    sourceAddressPubkey: env.userSource!,
                    transitTokenAccount: transitTokenAccountAddress,
                    destinationAddressPubkey: env.userDestinationTokenAccountAddress!,
                    feePayerPubkey: feePayerAddress,
                    network: network
                )
            )
        default:
            fatalError("unsupported swap type")
        }
    }
}
