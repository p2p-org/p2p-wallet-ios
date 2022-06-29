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
    static var endpoint: String {
        var config = String.secretConfig("FEE_RELAYER_ENDPOINT")!
        #if DEBUG
            if let stagingEndpoint = String.secretConfig("FEE_RELAYER_STAGING_ENDPOINT"), !stagingEndpoint.isEmpty {
                config = stagingEndpoint
            }
        #endif
        return "https://\(config)/name_register"
    }

    static var captchaAPI1Url: String {
        NameServiceImpl.endpoint + "/auth/gt/register"
    }
}
