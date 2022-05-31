//
//  RestoreICloud.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import Foundation
import RxCocoa
import SolanaSwift

enum RestoreICloud {
    struct ParsedAccount: Hashable {
        let account: RawAccount
        let parsedAccount: SolanaSwift.Account
    }
}
