//
//  OnboardingDebugViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 21.06.2023.
//

import Foundation
import Resolver
import Onboarding

class OnboardingViewModel: BaseViewModel, ObservableObject {
    @Injected var tkeyFacadeManager: TKeyFacadeManager
    @Injected var userWalletManager: UserWalletManager
    @Injected var remoteWalletMetadataProvider: RemoteWalletMetadataProvider
    @Injected var localWalletMetadataProvider: LocalWalletMetadataProvider

    @Published var tkeyInstance: String = "Init"
    @Published var ethAddressTkeyInstance: String = "Running"

    @Published var torusUserData: String = ""
    @Published var remoteMetadata: String = ""
    @Published var localMetadata: String = ""

    override init() {
        super.init()

        tkeyFacadeManager.latestPublisher.sink { [weak self] facade in
            if facade != nil {
                self?.tkeyInstance = "Running"
            } else {
                self?.tkeyInstance = "Nothing"
            }

            Task { [weak self] in
                self?.ethAddressTkeyInstance = await facade?.ethAddress ?? ""
            }

        }.store(in: &subscriptions)
    }

    func load() {
        Task {
            do {
                let userData = try await tkeyFacadeManager.latest?.getUserData()
                torusUserData = userData ?? "Nil"
            } catch {
                torusUserData = error.localizedDescription
            }
        }
    }

    func loadRemoteMetadata() {
        Task {
            guard let user = userWalletManager.wallet else {
                return
            }
            let data = try await remoteWalletMetadataProvider.load(for: user)
            remoteMetadata = data?.jsonString ?? "nil"
        }
    }

    func loadLocalMetadata() {
        Task {
            guard let user = userWalletManager.wallet else {
                return
            }
            let data = try await localWalletMetadataProvider.load(for: user)
            localMetadata = data?.jsonString ?? "nil"
        }
    }
}
