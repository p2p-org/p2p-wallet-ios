//
//  CreateOrRestoreReserveName.TextFieldState.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 29.11.2021.
//

extension CreateOrRestoreReserveName {
    enum TextFieldState {
        case available(name: String)
        case unavailable(name: String)
        case empty
    }
}
