//
//  DeviceTokenInfoDto.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

struct DeviceTokenInfo: Codable {
    let osName: String
    let osVersion: String
    let deviceModel: String
}
