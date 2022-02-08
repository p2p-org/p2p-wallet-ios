//
//  IntercomMessengerLauncher.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.02.2022.
//

import Intercom
import Resolver

final class IntercomMessengerLauncher: HelpCenterLauncher {
    private let attributesService = IntercomUserAttributesService()

    func launch() {
        attributesService.setParameters()

        Intercom.presentMessenger()
    }
}
