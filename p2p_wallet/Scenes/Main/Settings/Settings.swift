//
//  Settings.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import Foundation
import RxCocoa

enum Settings {
    enum NavigatableScene {
        case username
        case reserveUsername(owner: String, handler: ReserveNameHandler?)
        case backup
        case backupManually
        case backupShowPhrases
        case currency
        case network
        case security
        case changePincode
        case language
        case appearance
        case share(item: Any)
        case accessToPhoto
    }
    
    enum BiometryType {
        case none
        case touch
        case face
    }
}
