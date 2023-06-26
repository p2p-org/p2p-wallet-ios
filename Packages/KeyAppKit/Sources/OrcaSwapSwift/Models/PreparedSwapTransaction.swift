//
//  File.swift
//  
//
//  Created by Chung Tran on 15/02/2022.
//

import Foundation
import SolanaSwift

public struct PreparedSwapTransaction {
    public let instructions: [TransactionInstruction]
    public let signers: [KeyPair]
    public let accountCreationFee: Lamports
}
