//
//  BaseViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/06/2022.
//

import Combine
import Foundation

/*
 Don't make this class as ObservableObject because view stops updating itself if this protocol is inherited for some reason ONLY on iOS 14
 */

@MainActor
open class BaseViewModel {
    // MARK: - Properties

    var subscriptions = [AnyCancellable]()

    // MARK: - Deinitializer

    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }
}
