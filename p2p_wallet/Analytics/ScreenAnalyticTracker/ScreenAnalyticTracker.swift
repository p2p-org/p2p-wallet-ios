//
//  ScreenAnalyticTracker.swift
//  p2p_wallet
//
//  Created by Ivan on 14.09.2022.
//

import Foundation

class ScreenAnalyticTracker {
    static let shared = ScreenAnalyticTracker()

    private(set) var currentViewId = ""

    private init() {}

    func setCurrentViewId(_ viewId: String) {
        currentViewId = viewId
    }
}
