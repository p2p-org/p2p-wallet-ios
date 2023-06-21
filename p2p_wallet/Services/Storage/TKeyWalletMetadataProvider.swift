//
//  TKeyWalletMetadataProvider.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 09.06.2023.
//

import Foundation
import KeyAppKitCore
import Onboarding
import Resolver

actor TKeyWalletMetadataProvider: WalletMetadataProvider {
    var tkeyFacade: TKeyFacade?

    var ready: Bool {
        if tkeyFacade != nil {
            return true
        } else {
            let tkeyFacadeManager: TKeyFacadeManager = Resolver.resolve()
            return tkeyFacadeManager.latest != nil
        }
    }

    func acquireWrite() async {
        let tkeyFacadeManager: TKeyFacadeManager = Resolver.resolve()
        tkeyFacade = tkeyFacadeManager.latest
    }

    func releaseWrite() async {
        tkeyFacade = nil
    }

    func save(for userWallet: UserWallet, metadata: WalletMetaData?) async throws {
        let tkeyFacadeManager: TKeyFacadeManager = Resolver.resolve()

        guard
            let metadata,
            let tkeyFacade = tkeyFacade ?? tkeyFacadeManager.latest,
            metadata.ethPublic == userWallet.ethAddress,
            metadata.ethPublic == (await tkeyFacade.ethAddress)
        else {
            return
        }

        let serializedData = try metadata.serialize()

        guard let data = String(data: serializedData, encoding: .utf8) else {
            return
        }

        try await tkeyFacade.setUserData(data)
    }

    func load(for userWallet: UserWallet) async throws -> WalletMetaData? {
        let tkeyFacadeManager: TKeyFacadeManager = Resolver.resolve()

        guard
            let userWalletEthAddress = userWallet.ethAddress,
            let tkeyFacade = tkeyFacade ?? tkeyFacadeManager.latest,
            userWallet.ethAddress == (await tkeyFacade.ethAddress)
        else {
            return nil
        }

        guard
            let userData = try await tkeyFacade.getUserData(),
            !userData.isEmpty,
            let data = userData.data(using: .utf8)
        else {
            return nil
        }

        return try WalletMetaData.deserialize(
            data: data,
            ethAddress: userWalletEthAddress
        )
    }
}
