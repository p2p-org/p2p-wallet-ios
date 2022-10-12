//
//  ReserveName.TextFieldState.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 29.11.2021.
//

extension ReserveName {
    enum TextFieldState: Equatable {
        case available(name: String)
        case unavailable(name: String)
        case empty
    }
}
