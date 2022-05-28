//
//  NotifierEndpoint.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

enum NotifierEndpoint {
    case addDevice(dto: JsonRpcRequestDto<DeviceTokenDto>)
    case deleteDevice(dto: JsonRpcRequestDto<DeleteDeviceTokenDto>)
}

extension NotifierEndpoint: Endpoint {
    var path: String {
        "notifier"
    }

    var method: RequestMethod {
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
