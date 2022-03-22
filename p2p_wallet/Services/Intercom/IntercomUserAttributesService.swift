//
//  IntercomUserAttributesService.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.02.2022.
//

import Intercom
import Resolver
import SolanaSwift

final class IntercomUserAttributesService {
    @Injected private var nameStorage: NameStorageType
    @Injected private var walletsRepository: SolanaSDKAccountStorage

    func setParameters() {
        let userAddress = walletsRepository.account?.publicKey.base58EncodedString
        let name = nameStorage.getName()

        let userAttributes = ICMUserAttributes()
        userAttributes.name = name
        if let userAddress = userAddress {
            userAttributes.customAttributes = ["public_address": userAddress]
        }

        Intercom.updateUser(userAttributes)
    }
}
