//
//  LoggersAppDelegateService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import FeeRelayerSwift
import Foundation
import KeyAppKitLogger
import SolanaSwift

final class LoggersAppDelegateService: NSObject, AppDelegateService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if !DEBUG
        SentrySDK.start { options in
            options.dsn = .secretConfig("SENTRY_DSN")
            options.tracesSampleRate = 1.0
            options.enableNetworkTracking = true
            options.enableOutOfMemoryTracking = true
        }
        #endif

        var loggers: [LogManagerLogger] = [
            SentryLogger(),
        ]
        if Environment.current == .debug {
            loggers.append(LoggerSwiftLogger())
        }

        SolanaSwift.Logger.setLoggers(loggers as! [SolanaSwiftLogger])
        FeeRelayerSwift.Logger.setLoggers(loggers as! [FeeRelayerSwiftLogger])
        KeyAppKitLogger.Logger.setLoggers(loggers as! [KeyAppKitLoggerType])
        DefaultLogManager.shared.setProviders(loggers)

        return true
    }
}
