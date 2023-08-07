import Foundation

enum NotifierEndpoint {
    case addDevice(dto: JsonRpcRequestDto<DeviceTokenDto>)
    case deleteDevice(dto: JsonRpcRequestDto<DeleteDeviceTokenDto>)
}

extension NotifierEndpoint: Endpoint {
    var path: String {
        ""
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
