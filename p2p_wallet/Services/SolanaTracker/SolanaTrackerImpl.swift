//
//  SolanaTrackerImpl.swift
//  p2p_wallet
//
//  Created by Ivan on 14.10.2022.
//

import Combine
import FirebaseRemoteConfig
import Foundation
import Resolver
import SolanaSwift

class SolanaTrackerImpl: SolanaTracker {
    @Injected private var solanaApiClient: SolanaAPIClient

    private let unstableSolanaSubject = PassthroughSubject<Void, Never>()
    var unstableSolana: AnyPublisher<Void, Never> { unstableSolanaSubject.eraseToAnyPublisher() }

    private let limitForAnalyze: UInt = 3

    private let negativeStatusFrequency: SolanaNegativeFrequency?
    private let negativeStatusPercent: Int?
    private let negativeStatusTimeFrequency: TimeInterval

    private var average: Int?

    private var solanaWasUnstable = false

    init(
        solanaNegativeStatusFrequency: SolanaNegativeFrequency? = nil,
        solanaNegativeStatusPercent: Int? = nil,
        solanaNegativeStatusTimeFrequency: Int? = nil
    ) {
        negativeStatusFrequency = solanaNegativeStatusFrequency ?? SolanaNegativeFrequency(
            rawValue: (Defaults.solanaNegativeStatusFrequency ?? "").lowercased()
        )
        negativeStatusPercent = solanaNegativeStatusPercent ?? Defaults.solanaNegativeStatusPercent
        negativeStatusTimeFrequency = TimeInterval(
            solanaNegativeStatusTimeFrequency ?? Defaults.solanaNegativeStatusTimeFrequency ?? 10
        )
    }

    func startTracking() {
        Task {
            guard let negativePercent = negativeStatusPercent else { return }

            guard
                let model = try? await solanaApiClient.getRecentPerformanceSamples(limit: [limitForAnalyze])
            else {
                solanaBecameUnstable()
                startTimerIfNeeded()
                return
            }

            let newAverage = calculatedAverage(model: model)
            if let cachedAverage = self.average {
                if cachedAverage - newAverage > negativePercent {
                    solanaBecameUnstable()
                }
            }
            self.average = newAverage
            startTimerIfNeeded()
        }
    }

    private func calculatedAverage(model: [PerfomanceSamples]) -> Int {
        let numTransactionsSum = model.map(\.numTransactions).reduce(0, +)
        let samplePeriodSecsSum = model.map(\.samplePeriodSecs).reduce(0, +)
        return numTransactionsSum / samplePeriodSecsSum
    }

    private func startTimerIfNeeded() {
        if negativeStatusFrequency == .once, solanaWasUnstable { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + negativeStatusTimeFrequency) {
            self.startTracking()
        }
    }

    private func solanaBecameUnstable() {
        unstableSolanaSubject.send()
        solanaWasUnstable = true
    }
}

// MARK: - Negative Frequency

extension SolanaTrackerImpl {
    enum SolanaNegativeFrequency: String {
        case once
        case moreThanOnce = "more_than_once"
    }
}
