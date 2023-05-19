//
//  NotifierEndpoint.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation
import KeyAppNetworking

enum NotifierEndpoint {
    case addDevice(dto: JsonRpcRequestDto<DeviceTokenDto>)
    case deleteDevice(dto: JsonRpcRequestDto<DeleteDeviceTokenDto>)
}

// MARK: - Endpoint

extension NotifierEndpoint: HTTPEndpoint {
    var baseURL: String {
        GlobalAppState.shared.pushServiceEndpoint
    }
    
    var header: [String: String] {
        [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "CHANNEL_ID": "P2PWALLET_MOBILE",
        ]
    }
    
    var path: String {
        ""
    }

    var method: HTTPMethod {
        .post
    }

    var body: String? {
        switch self {
        case let .addDevice(dto):
            return dto.snakeCaseEncoded
        case let .deleteDevice(dto):
            return dto.snakeCaseEncoded
        }
    }
}
