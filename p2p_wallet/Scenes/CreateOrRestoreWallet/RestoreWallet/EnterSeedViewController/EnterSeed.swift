//
//  EnterSeed.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.11.2021.
//

import Foundation
import RxCocoa

enum EnterSeed {
    enum NavigatableScene {
        case info
        case back
        case termsAndConditions
        case success(words: [String])
    }
}
