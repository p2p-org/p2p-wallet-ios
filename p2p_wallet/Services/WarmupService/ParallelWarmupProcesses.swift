// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FirebaseRemoteConfig
import Foundation
import Resolver
import SolanaSwift
import Sell

class ParallelWarmupProcesses: WarmupProcess {
    
    // MARK: - Dependencies

    @Injected private var sellDataService: any SellDataService
    
    // MARK: - Methods
    func start() async {
        // Sell availability
        if available(.sellScenarioEnabled) {
            await sellDataService.checkAvailability()
        }
    }
}
