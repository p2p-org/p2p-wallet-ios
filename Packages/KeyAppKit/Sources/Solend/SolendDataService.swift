// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import FeeRelayerSwift
import Foundation
import P2PSwift
import SolanaSwift

public enum SolendDataStatus {
    case initialized
    case updating
    case ready
}

public protocol SolendDataService {
    var status: AnyPublisher<SolendDataStatus, Never> { get }
    var error: AnyPublisher<Error?, Never> { get }
    var lastUpdateDate: AnyPublisher<Date, Never> { get }
    
    var availableAssets: AnyPublisher<[SolendConfigAsset]?, Never> { get }
    var deposits: AnyPublisher<[SolendUserDeposit]?, Never> { get }
    var marketInfo: AnyPublisher<[SolendMarketInfo]?, Never> { get }

    func clearDeposits()
    func update() async throws
}
