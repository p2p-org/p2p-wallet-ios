//
//  File.swift
//
//
//  Created by Giang Long Tran on 08.06.2023.
//

import AnalyticsManager
import Combine
import Foundation
import WebKit

public protocol TKeyFacadeManager {
    func create(_ wkWebview: WKWebView, with config: TKeyJSFacadeConfiguration) -> TKeyJSFacade

    var latest: TKeyFacade? { get }
    var latestPublisher: AnyPublisher<TKeyFacade?, Never> { get }
}

public class TKeyFacadeManagerImpl: TKeyFacadeManager {
    let analyticsManager: AnalyticsManager
    let invalidTime: TimeInterval = 60 * 15

    var timer: Timer?
    var _latest: CurrentValueSubject<TKeyFacade?, Never> = .init(nil)
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
        _latest.value = tkeyFacade
        latestCreateDate = Date()

        return tkeyFacade
    }

    public var latest: TKeyFacade? {
        guard let latestCreateDate else {
            return nil
        }

        if Date().timeIntervalSince(latestCreateDate) < invalidTime {
            // Facade is still alive
            return _latest.value
        } else {
            // Lifetime of facade is expired. Clean latest state.
            _latest.value = nil
            self.latestCreateDate = nil

            return nil
        }
    }

    public var latestPublisher: AnyPublisher<TKeyFacade?, Never> {
        _latest.eraseToAnyPublisher()
    }
}
