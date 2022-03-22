//
//  SwapProvider.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/09/2021.
//

import Foundation

enum SwapProvider {
    case serum
    case orca

    var active: Self { .orca }
}
