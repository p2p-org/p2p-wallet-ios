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
    static let endpoint = "\(FeeRelayerEndpoint.baseUrl)/name_register"

    static var captchaAPI1Url: String {
        NameServiceImpl.endpoint + "/auth/gt/register"
    }
}
