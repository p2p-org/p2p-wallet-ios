//
//  RestoreICloud.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import Foundation
import RxCocoa

struct RestoreICloud {
    struct ParsedAccount: Hashable {
        let account: Account
        let parsedAccount: SolanaSDK.Account
    }
}
