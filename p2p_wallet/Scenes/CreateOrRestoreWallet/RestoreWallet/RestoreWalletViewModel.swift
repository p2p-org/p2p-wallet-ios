// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver
import SolanaSwift

struct RestoreOption: OptionSet {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let keychain = RestoreOption(rawValue: 1 << 0)
    static let seed = RestoreOption(rawValue: 1 << 1)
    static let custom = RestoreOption(rawValue: 1 << 2)
    static let socialApple = RestoreOption(rawValue: 1 << 3)
    static let socialGoogle = RestoreOption(rawValue: 1 << 4)
}

final class RestoreWalletViewModel: BaseViewModel {
    let deviceShare: String?
    let availableRestoreOptions: RestoreOption
    let stateMachine: RestoreWalletStateMachine

    @Injected var authService: AuthService

    override init() {
        // TODO: Move into a single TKeyFacade provider for create and restore wallet
        let tKeyFacade: TKeyFacade = available(.mockedTKeyFacade) ?
            TKeyMockupFacade() :
            TKeyJSFacade(
                wkWebView: GlobalWebView.requestWebView(),
                config: .init(
                    metadataEndpoint: OnboardingConfig.shared.metaDataEndpoint,
                    torusEndpoint: OnboardingConfig.shared.torusEndpoint,
                    torusNetwork: "testnet",
                    torusVerifierMapping: [
                        "google": OnboardingConfig.shared.torusGoogleVerifier,
                        "apple": OnboardingConfig.shared.torusAppleVerifier,
                    ]
                )
            )

        #if !RELEASE
            let apiGatewayEndpoint = String.secretConfig("API_GATEWAY_DEV")!
        #else
            let apiGatewayEndpoint = String.secretConfig("API_GATEWAY_PROD")!
        #endif

        let apiGatewayClient: APIGatewayClient = available(.mockedApiGateway) ?
            APIGatewayClientImplMock() :
            APIGatewayClientImpl(endpoint: apiGatewayEndpoint)

        let accountStorage: AccountStorageType = Resolver.resolve()
        deviceShare = available(.mockedDeviceShare) ? "someDeviceShare" : accountStorage.deviceShare

        let keychainStorage: KeychainStorage = Resolver.resolve()

        stateMachine = .init(provider: RestoreWalletFlowContainer(
            tKeyFacade: tKeyFacade,
            deviceShare: deviceShare,
            authService: AuthServiceBridge(),
            apiGatewayClient: apiGatewayClient,
            icloudAccountProvider: keychainStorage
        ))

        var options: RestoreOption = [.seed, .custom]
        if deviceShare != nil {
            options.insert(RestoreOption.socialApple)
            options.insert(RestoreOption.socialGoogle)
        }

        // If icloud stores some accounts
        if
            let accounts = keychainStorage.accountFromICloud(),
            !accounts.isEmpty
        {
            options.insert(RestoreOption.keychain)
        }

        availableRestoreOptions = options

        super.init()
    }
}

extension KeychainStorage: ICloudAccountProvider {
    func getAll() async throws -> [(name: String?, phrase: String, derivablePath: DerivablePath)] {
        guard let accounts = accountFromICloud() else { return [] }
        return accounts.map { (name: $0.name, phrase: $0.phrase, derivablePath: $0.derivablePath) }
    }
}
