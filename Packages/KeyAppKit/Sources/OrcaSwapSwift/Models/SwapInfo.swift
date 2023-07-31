//
//  File.swift
//  
//
//  Created by Chung Tran on 13/10/2021.
//

import Foundation

public struct SwapInfo {
    let routes: Routes
    let tokens: [String: TokenValue]
    let pools: Pools
    let programIds: ProgramIDS
    let tokenNames: [String: String] // [Mint: TokenName]
}
