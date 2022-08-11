//
//  ReserveName.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 26.11.2021.
//

import Foundation

enum ReserveName {
    enum NavigatableScene {
        case termsOfUse
        case privacyPolicy
        case skipAlert((Bool) -> Void)
        case back
    }
}
