//
//  SendToken.ChooseRecipientAndNetwork.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation

extension SendToken {
    enum ChooseRecipientAndNetwork {
        enum NavigatableScene {
            case chooseNetwork
            case backToConfirmation // available only when viewModel.showAfterConfirmation = true
        }
    }
}
