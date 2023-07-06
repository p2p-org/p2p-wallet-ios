//
//  DeviceTokenResposeDto.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

struct DeviceTokenResponseDto: Decodable {
    let deviceToken: String
    let timestamp: String
    let clientId: String
}
