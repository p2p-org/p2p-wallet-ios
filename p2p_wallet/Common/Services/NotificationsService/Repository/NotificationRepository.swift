import Foundation
import Resolver

protocol NotificationRepository {
    typealias DeviceTokenResponse = JsonRpcResponseDto<DeviceTokenResponseDto>

    func sendDeviceToken(model: DeviceTokenDto) async throws -> DeviceTokenResponse
    func removeDeviceToken(model: DeleteDeviceTokenDto) async throws -> DeviceTokenResponse
}

final class NotificationRepositoryImpl: NotificationRepository {
    let httpClient = HttpClientImpl()

    func sendDeviceToken(model: DeviceTokenDto) async throws -> DeviceTokenResponse {
        do {
            return try await httpClient.sendRequest(
                endpoint: NotifierEndpoint.addDevice(dto: .init(
                    method: "add_device",
                    params: [model]
                )),
                responseModel: DeviceTokenResponse.self
            )
        } catch let error as JsonRpcError {
            if error.code == -32001 {
                return .init(
                    id: "",
                    result: .init(
                        deviceToken: model.deviceToken,
                        timestamp: String(Date().timeIntervalSince1970),
                        clientId: model.clientId
                    )
                )
            }
            throw error
        } catch {
            throw error
        }
    }

    func removeDeviceToken(model: DeleteDeviceTokenDto) async throws -> DeviceTokenResponse {
        try await httpClient.sendRequest(
            endpoint: NotifierEndpoint.deleteDevice(dto: .init(
                method: "delete_device",
                params: [model]
            )),
            responseModel: DeviceTokenResponse.self
        )
    }
}
