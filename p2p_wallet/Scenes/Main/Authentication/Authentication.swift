//
//  Authentication.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//
import Foundation

enum Authentication {
    enum ExtraAction {
        case reset
        case signOut
        case none
    }

    enum NavigatableScene {
        case resetPincodeWithASeedPhrase
        case signOutAlert(_ onLogout: BEVoidCallback)
    }
}
