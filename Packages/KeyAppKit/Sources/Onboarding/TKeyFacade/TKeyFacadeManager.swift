//
//  File.swift
//
//
//  Created by Giang Long Tran on 08.06.2023.
//

import AnalyticsManager
import Foundation
import WebKit

public protocol TKeyFacadeManager {
    func create(_ wkWebview: WKWebView, with config: TKeyJSFacadeConfiguration) -> TKeyJSFacade

    var latest: TKeyFacade? { get }
}

public class TKeyFacadeManagerImpl: TKeyFacadeManager {
    let analyticsManager: AnalyticsManager
    let invalidTime: TimeInterval = 60 * 15

    var timer: Timer?
    var _latest: TKeyFacade?
    var latestCreateDate: Date?

    public init(analyticsManager: AnalyticsManager) {
        self.analyticsManager = analyticsManager

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true, block: { [weak self] _ in
            _ = self?.latest
        })
    }

    deinit {
        timer?.invalidate()
    }

    public func create(_ wkWebview: WKWebView, with config: TKeyJSFacadeConfiguration) -> TKeyJSFacade {
        let tkeyFacade = TKeyJSFacade(wkWebView: wkWebview, config: config, analyticsManager: analyticsManager)
        _latest = tkeyFacade
        latestCreateDate = Date()

        return tkeyFacade
    }

    public var latest: TKeyFacade? {
        guard let latestCreateDate else {
            return nil
        }

        if Date().timeIntervalSince(latestCreateDate) < invalidTime {
            // Facade is still alive
            return _latest
        } else {
            // Lifetime of facade is expired. Clean latest state.
            _latest = nil
            self.latestCreateDate = nil

            return nil
        }
    }
}
