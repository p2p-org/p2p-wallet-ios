//
//  ErrorHandler.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 04.03.2023.
//

import Foundation

extension Error {
    func capture() {
        DefaultLogManager.shared.log(error: self)
    }
}
