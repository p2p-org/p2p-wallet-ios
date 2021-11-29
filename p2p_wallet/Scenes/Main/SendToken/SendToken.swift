//
//  SendToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxCocoa

struct SendToken {
    enum NavigatableScene {
        case back
        case chooseTokenAndAmount
        case chooseRecipientAndNetwork
        case confirmation
    }
}
