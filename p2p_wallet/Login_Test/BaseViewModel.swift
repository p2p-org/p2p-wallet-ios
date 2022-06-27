//
//  BaseViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/06/2022.
//

import Combine
import Foundation

class BaseViewModel: ObservableObject {
    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }
}
