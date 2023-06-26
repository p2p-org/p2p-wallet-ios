// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import OrcaSwapSwift

extension SwapTransactionBuilderImpl {
    func checkClosingAccount(
        owner: PublicKey,
        feePayer: PublicKey,
        destinationTokenMint: PublicKey,
        minimumTokenAccountBalance: UInt64,
        env: inout SwapTransactionBuilderOutput
    ) throws {
        if let newAccount = env.sourceWSOLNewAccount {
            env.instructions.append(contentsOf: [
                TokenProgram.closeAccountInstruction(
                    account: newAccount.publicKey,
                    destination: owner,
                    owner: owner
                )
            ])
        }
        // close destination
        if let newAccount = env.destinationNewAccount, destinationTokenMint == .wrappedSOLMint {
            env.instructions.append(contentsOf: [
                TokenProgram.closeAccountInstruction(
                    account: newAccount.publicKey,
                    destination: owner,
                    owner: owner
                ),
                SystemProgram.transferInstruction(
                    from: owner,
                    to: feePayer,
                    lamports: minimumTokenAccountBalance
                )
            ])
            env.accountCreationFee -= minimumTokenAccountBalance
        }
    }
}

