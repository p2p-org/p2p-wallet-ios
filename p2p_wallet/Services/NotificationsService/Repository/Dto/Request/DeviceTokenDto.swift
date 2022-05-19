//
//  DeviceTokenDto.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

struct DeviceTokenDto: Encodable {
    let deviceToken: String
    let clientId: String
    let type = "device"
    let deviceInfo: DeviceTokenInfo?
}
