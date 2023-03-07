// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AnalyticsManager
import Foundation
import JSBridge
import WebKit

public enum TKeyVerifierStrategy {
    case single(verifier: String)
    case aggregate(verifier: String, subVerifier: String)
}

public struct TKeyJSFacadeConfiguration {
    let torusEndpoint: String
    let torusNetwork: String
    let verifierStrategyResolver: (_ authProvider: String) -> TKeyVerifierStrategy

    public init(
        torusEndpoint: String,
        torusNetwork: String,
        verifierStrategyResolver: @escaping (_ authProvider: String) -> TKeyVerifierStrategy
    ) {
        self.torusEndpoint = torusEndpoint
        self.torusNetwork = torusNetwork
        self.verifierStrategyResolver = verifierStrategyResolver
    }
}

public actor TKeyJSFacade: TKeyFacade {
    enum Error: Swift.Error {
        case canNotFindJSScript
        case facadeIsNotReady
        case invalidReturnValue
    }

    private let kLibrary: String = "p2pWeb3Auth"

    private let context: JSBContext
    private var facadeClass: JSBValue?
    private let config: TKeyJSFacadeConfiguration
    private let analyticsManager: AnalyticsManager

    public init(
        wkWebView: WKWebView? = nil,
        config: TKeyJSFacadeConfiguration,
        analyticsManager: AnalyticsManager
    ) {
        self.config = config
        context = JSBContext(wkWebView: wkWebView)
        self.analyticsManager = analyticsManager
    }

    deinit {
        Task.detached { [context] in await context.dispose() }
    }

    private var ready: Bool = false

    public func initialize() async throws {
        guard ready == false else { return }
        defer { ready = true }

        await clearWebStorage()
        let scriptPath = getSDKPath()
        let request = URLRequest(url: URL(fileURLWithPath: scriptPath))
        try await context.load(request: request)
        facadeClass = try await context.this.valueForKey("\(kLibrary).IosFacade")
    }

    @MainActor
    private func clearWebStorage() async {
        let records = await WKWebsiteDataStore.default()
            .fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes())
        for record in records {
            await WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record])
        }
    }

    private func getSDKPath() -> String {
        #if SWIFT_PACKAGE
            guard let scriptPath = Bundle.module.path(forResource: "index", ofType: "html") else {
                fatalError(Error.canNotFindJSScript.localizedDescription)
            }
        #else
            guard let scriptPath = Bundle(for: TKeyJSFacade.self).path(forResource: "index", ofType: "html") else {
                fatalError(Error.canNotFindJSScript.localizedDescription)
            }
        #endif

        return scriptPath
    }

    private func getFacade(configuration: [String: Any]) async throws -> JSBValue {
        let library = try getLibrary()
        return try await library.invokeNew(
            withArguments: [
                [
                    "torusEndpoint": config.torusEndpoint,
                    "torusNetwork": config.torusNetwork,
                ].merging(configuration, uniquingKeysWith: { $1 }),
            ]
        )
    }

    public func obtainTorusKey(tokenID: TokenID) async throws -> TorusKey {
        let startDate = Date()
        let method = "obtainTorusKey"
        
        defer { logTorusAnalyticsEvent(startDate: startDate, methodName: method) }

        do {
            var facadeConfig: [String: Any] = [
                "type": "signin",
                "torusLoginType": tokenID.provider,
            ]

            switch config.verifierStrategyResolver(tokenID.provider) {
            case let .single(verifier):
                facadeConfig["torusVerifier"] = verifier
            case let .aggregate(verifier, subVerifier):
                facadeConfig["torusVerifier"] = verifier
                facadeConfig["torusSubVerifier"] = subVerifier
            }

            let facade = try await getFacade(configuration: facadeConfig)
            let value = try await facade.invokeAsyncMethod(method, withArguments: [tokenID.value])

            guard let torusKey = try await value.toString() else {
                throw Error.invalidReturnValue
            }

            return .init(tokenID: tokenID, value: torusKey)
        } catch let JSBError.jsError(error) {
            let parsedError = parseFacadeJSError(error: error)
            throw parsedError ?? JSBError.jsError(error)
        } catch {
            throw error
        }
    }

    private func logTorusAnalyticsEvent(startDate: Date, methodName: String) {
        let secondsDifference = Date().timeIntervalSince(startDate)
        let minutes = Int(secondsDifference / 60)
        let seconds = Int(secondsDifference) % 60
        
        analyticsManager.log(event: TorusAnalyticsEvent.onboardingTorusRequest(
            methodName: methodName,
            minutes: minutes,
            seconds: seconds,
            milliseconds: 0
        ))
    }

    public func signUp(torusKey: TorusKey, privateInput: String) async throws -> SignUpResult {
        do {
            var facadeConfig: [String: Any] = [
                "type": "signup",
                "useNewEth": true,
                "torusLoginType": torusKey.tokenID.provider,
                "privateInput": privateInput,
            ]

            switch config.verifierStrategyResolver(torusKey.tokenID.provider) {
            case let .single(verifier):
                facadeConfig["torusVerifier"] = verifier
            case let .aggregate(verifier, subVerifier):
                facadeConfig["torusVerifier"] = verifier
                facadeConfig["torusSubVerifier"] = subVerifier
            }

            let facade = try await getFacade(configuration: facadeConfig)
            let value = try await facade.invokeAsyncMethod("triggerSilentSignup", withArguments: [torusKey.value])

            guard
                let privateSOL = try await value.valueForKey("privateSOL").toString(),
                let reconstructedETH = try await value.valueForKey("ethAddress").toString(),
                let deviceShare = try await value.valueForKey("deviceShare").toJSON(),
                let customShare = try await value.valueForKey("customShare").toJSON(),
                let metadata = try await value.valueForKey("metadata").toJSON()
            else {
                throw Error.invalidReturnValue
            }

            return .init(
                privateSOL: privateSOL,
                reconstructedETH: reconstructedETH,
                deviceShare: deviceShare,
                customShare: customShare,
                metaData: metadata
            )
        } catch let JSBError.jsError(error) {
            let parsedError = parseFacadeJSError(error: error)
            throw parsedError ?? JSBError.jsError(error)
        } catch {
            throw error
        }
    }

    public func signIn(torusKey: TorusKey, deviceShare: String) async throws -> SignInResult {
        do {
            var facadeConfig: [String: Any] = [
                "type": "signin",
                "torusLoginType": torusKey.tokenID.provider,
            ]

            switch config.verifierStrategyResolver(torusKey.tokenID.provider) {
            case let .single(verifier):
                facadeConfig["torusVerifier"] = verifier
            case let .aggregate(verifier, subVerifier):
                facadeConfig["torusVerifier"] = verifier
                facadeConfig["torusSubVerifier"] = subVerifier
            }

            let facade = try await getFacade(configuration: facadeConfig)
            let value = try await facade.invokeAsyncMethod(
                "triggerSignInNoCustom",
                withArguments: [torusKey.value, deviceShare]
            )

            guard
                let privateSOL = try await value.valueForKey("privateSOL").toString(),
                let reconstructedETH = try await value.valueForKey("ethAddress").toString()
            else { throw Error.invalidReturnValue }

            return .init(
                privateSOL: privateSOL,
                reconstructedETH: reconstructedETH
            )
        } catch let JSBError.jsError(error) {
            let parsedError = parseFacadeJSError(error: error)
            throw parsedError ?? JSBError.jsError(error)
        } catch {
            throw error
        }
    }

    public func signIn(torusKey: TorusKey, customShare: String,
                       encryptedMnemonic: String) async throws -> SignInResult
    {
        do {
            var facadeConfig: [String: Any] = [
                "type": "signin",
                "torusLoginType": torusKey.tokenID.provider,
            ]

            switch config.verifierStrategyResolver(torusKey.tokenID.provider) {
            case let .single(verifier):
                facadeConfig["torusVerifier"] = verifier
            case let .aggregate(verifier, subVerifier):
                facadeConfig["torusVerifier"] = verifier
                facadeConfig["torusSubVerifier"] = subVerifier
            }

            let facade = try await getFacade(configuration: facadeConfig)
            let encryptedMnemonic = try await JSBValue(jsonString: encryptedMnemonic, in: context)
            let value = try await facade.invokeAsyncMethod(
                "triggerSignInNoDevice",
                withArguments: [torusKey.value, customShare, encryptedMnemonic]
            )
            guard
                let privateSOL = try await value.valueForKey("privateSOL").toString(),
                let reconstructedETH = try await value.valueForKey("ethAddress").toString()
            else { throw Error.invalidReturnValue }

            return .init(
                privateSOL: privateSOL,
                reconstructedETH: reconstructedETH
            )
        } catch let JSBError.jsError(error) {
            let parsedError = parseFacadeJSError(error: error)
            throw parsedError ?? JSBError.jsError(error)
        } catch {
            throw error
        }
    }

    public func signIn(
        deviceShare: String,
        customShare: String,
        encryptedMnemonic: String
    ) async throws -> SignInResult {
        do {
            // It doesn't matter which login type and torus verifier
            var facadeConfig: [String: Any] = [
                "type": "signin",
                "torusLoginType": "google",
            ]

            switch config.verifierStrategyResolver("google") {
            case let .single(verifier):
                facadeConfig["torusVerifier"] = verifier
            case let .aggregate(verifier, subVerifier):
                facadeConfig["torusVerifier"] = verifier
                facadeConfig["torusSubVerifier"] = subVerifier
            }
            let facade = try await getFacade(configuration: facadeConfig)
            let encryptedMnemonic = try await JSBValue(jsonString: encryptedMnemonic, in: context)
            let value = try await facade.invokeAsyncMethod(
                "triggerSignInNoTorus",
                withArguments: [deviceShare, customShare, encryptedMnemonic]
            )
            guard
                let privateSOL = try await value.valueForKey("privateSOL").toString(),
                let reconstructedETH = try await value.valueForKey("ethAddress").toString()
            else { throw Error.invalidReturnValue }

            return .init(
                privateSOL: privateSOL,
                reconstructedETH: reconstructedETH
            )
        } catch let JSBError.jsError(error) {
            let parsedError = parseFacadeJSError(error: error)
            throw parsedError ?? JSBError.jsError(error)
        } catch {
            throw error
        }
    }

    func getLibrary() throws -> JSBValue {
        guard let library = facadeClass else {
            throw Error.facadeIsNotReady
        }
        return library
    }

    internal func parseFacadeJSError(error: Any) -> TKeyFacadeError? {
        guard
            let errorStr = error as? String,
            let error = errorStr.data(using: .utf8)
        else { return nil }

        return try? JSONDecoder().decode(TKeyFacadeError.self, from: error)
    }
}

extension WKWebsiteDataStore {
    func fetchDataRecords(ofTypes dataTypes: Set<String>) async -> [WKWebsiteDataRecord] {
        await withCheckedContinuation { continuation in
            fetchDataRecords(ofTypes: dataTypes) { records in
                continuation.resume(returning: records)
            }
        }
    }
}

// MARK: - TorusAnalyticsEvent

private extension TKeyJSFacade {
    enum TorusAnalyticsEvent: AnalyticsEvent {
        case onboardingTorusRequest(
            methodName: String,
            minutes: Int,
            seconds: Int,
            milliseconds: Int
        )
        
        var name: String? {
            switch self {
            case .onboardingTorusRequest:
                return "Onboarding_Torus_Request"
            }
        }
        
        var params: [String: Any]? {
            switch self {
            case let .onboardingTorusRequest(methodName, minutes, seconds, milliseconds):
                return [
                    "Method_Name": methodName,
                    "Minutes": minutes,
                    "Seconds": seconds,
                    "Milliseconds": milliseconds
                ]
            }
        }
        
        // FIXME: - Later
        var providerIds: [AnalyticsProviderId] {
            ["amplitude"]
        }
    }
}

