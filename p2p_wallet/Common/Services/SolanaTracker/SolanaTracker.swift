//
//  SolanaTracker.swift
//  p2p_wallet
//
//  Created by Ivan on 14.10.2022.
//

import Combine
import Foundation

protocol SolanaTracker {
    var unstableSolana: AnyPublisher<Void, Never> { get }

    func startTracking()
    func stopTracking()
}
