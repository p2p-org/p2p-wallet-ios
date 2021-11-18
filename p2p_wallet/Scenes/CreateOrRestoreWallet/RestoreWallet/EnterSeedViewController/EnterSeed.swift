//
//  EnterSeed.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.11.2021.
//

import Foundation
import RxCocoa

struct EnterSeed {
    enum NavigatableScene {
        case info
        case back
        case success(words: [String])
    }
}
