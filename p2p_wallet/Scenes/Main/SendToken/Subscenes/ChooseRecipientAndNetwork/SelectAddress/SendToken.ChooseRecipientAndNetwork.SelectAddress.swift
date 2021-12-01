//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import RxCocoa

extension SendToken.ChooseRecipientAndNetwork {
    struct SelectAddress {
        enum NavigatableScene {
            case scanQrCode
        }
        
        enum InputState: Equatable {
            case searching
            case recipientSelected
        }
    }
}
