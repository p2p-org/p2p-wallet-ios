// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FirebaseRemoteConfig
import Foundation
import Resolver
import SolanaSwift

class RemoteConfigWarmupProcess: WarmupProcess {
    func start() async {
        await setupRemoteConfig(timeout: 3.0)
    }

    private func setupRemoteConfig(timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            setupRemoteConfig(timeout: timeout) {
                continuation.resume()
            }
        }
    }

    /// Setup remote configuration
    ///
    /// - Parameters:
    ///   - timeout: completion will call after timeout. The fetching will continue in background.
    ///   - completion: the closure will be called after successful fetching or timeout one time.
    private func setupRemoteConfig(timeout: TimeInterval, completion: (() -> Void)?) {
        var completion = completion

        let timer = TimeoutHandler(timeout) {
            if completion != nil {
                completion?()
                completion = nil
            }
        }

        let currentEndpoints = APIEndPoint.definedEndpoints
        #if !RELEASE
            let settings = RemoteConfigSettings()
            // WARNING: Don't actually do this in production!
            settings.minimumFetchInterval = 0
            RemoteConfig.remoteConfig().configSettings = settings

            FeatureFlagProvider.shared.fetchFeatureFlags(
                mainFetcher: MergingFlagsFetcher(
                    primaryFetcher: DebugMenuFeaturesProvider.shared,
                    secondaryFetcher: MergingFlagsFetcher(
                        primaryFetcher: defaultFlags,
                        secondaryFetcher: RemoteConfig.remoteConfig()
                    )
                )
            ) { _ in
                self.changeEndpointIfNeeded(currentEndpoints: currentEndpoints)
                self.cacheConfigValues()
                if completion != nil {
                    completion?()
                    timer.cancel()
                }
            }
        #else
            FeatureFlagProvider.shared.fetchFeatureFlags(
                mainFetcher: MergingFlagsFetcher(
                    primaryFetcher: RemoteConfig.remoteConfig(),
                    secondaryFetcher: defaultFlags
                )
            ) { _ in
                self.changeEndpointIfNeeded(currentEndpoints: currentEndpoints)
                self.cacheConfigValues()
                if completion != nil {
                    completion?()
                    timer.cancel()
                }
            }
        #endif

    }

    private func changeEndpointIfNeeded(currentEndpoints: [APIEndPoint]) {
        let newEndpoints = APIEndPoint.definedEndpoints
        guard currentEndpoints != newEndpoints else { return }
        if
            !(newEndpoints.contains { $0 == Defaults.apiEndPoint }),
            let firstEndpoint = newEndpoints.first
        {
            Resolver.resolve(ChangeNetworkResponder.self).changeAPIEndpoint(to: firstEndpoint)
        }
    }

    private func cacheConfigValues() {
        let remoteConfig = RemoteConfig.remoteConfig()
        Defaults.solanaNegativeStatusFrequency = remoteConfig.solanaNegativeStatusFrequency
        Defaults.solanaNegativeStatusPercent = remoteConfig.solanaNegativeStatusPercent
        Defaults.solanaNegativeStatusTimeFrequency = remoteConfig.solanaNegativeStatusTimeFrequency
        Defaults.swapRouteRefeshRate = remoteConfig.swapRouteRefresh
    }
}

private class TimeoutHandler: NSObject {
    private var timer: Timer?
    private var callback: (() -> Void)?

    init(_ delaySeconds: TimeInterval, _ callback: @escaping () -> Void) {
        super.init()
        self.callback = callback
        timer = Timer.scheduledTimer(withTimeInterval: delaySeconds, repeats: false) { [weak self] _ in
            self?.invoke()
        }
    }

    func invoke() {
        callback?()
        callback = nil
        timer = nil
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
