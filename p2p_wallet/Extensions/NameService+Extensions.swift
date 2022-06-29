//
//  NameServiceUserDefaultCache.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2022.
//

import Foundation
import NameService
import Resolver

extension NameServiceImpl {
    /// Name register service does not depend on Fee relayer service so we don't use FeeRelayerEndpoint here.
    /// They share single server for now but logically settings should be splitted.
    static let endpoint = "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)/name_register"

    static var captchaAPI1Url: String {
        NameServiceImpl.endpoint + "/auth/gt/register"
    }
}
