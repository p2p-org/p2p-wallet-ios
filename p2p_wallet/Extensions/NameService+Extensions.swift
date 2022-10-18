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
    static let endpoint: String = {
        if Environment.current == .release {
            return "https://\(String.secretConfig("NAME_SERVICE_ENDPOINT")!)"
        }
        return "https://\(String.secretConfig("NAME_SERVICE_STAGING_ENDPOINT")!)"
    }()

    static var captchaAPI1Url: String {
        NameServiceImpl.endpoint + "/auth/gt/register"
    }
}
