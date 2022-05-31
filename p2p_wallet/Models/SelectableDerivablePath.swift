//
//  DerivablePath.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import SolanaSwift

struct SelectableDerivablePath: Hashable {
    let path: SolanaSDK.DerivablePath
    var isSelected: Bool
}
