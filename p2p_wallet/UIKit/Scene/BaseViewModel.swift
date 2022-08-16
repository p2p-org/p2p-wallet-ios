//
//  BaseViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/08/2022.
//

import Combine
import Foundation

@MainActor
open class BaseViewModel: ObservableObject {
    // MARK: - Properties

    var subscriptions = [AnyCancellable]()

    // MARK: - Deinitializer

    deinit {
        print("\(String(describing: self)) deinited")
    }
}
