// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import Solend

enum InvestSolendBannerState {
    case loading
    case welcome
    case reward
    case processing
    case actionError(SolendAction)
    case anotherError
}

class InvestSolendBannerCenterViewModel: ObservableObject {
    @Published var state: InvestSolendBannerState = .loading
    
    private let dataService: SolendDataService
    private let actionService: SolendActionService
    
    init(dataService: SolendDataService, actionService: SolendActionService) {
        self.dataService = dataService
        self.actionService = actionService
    }
    
    
}
