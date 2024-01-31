import Foundation
import KeyAppNetworking
import Resolver

protocol NotificationRepository {
    func sendDeviceToken(model: DeviceTokenDto) async throws -> DeviceTokenResponseDto
    func removeDeviceToken(model: DeleteDeviceTokenDto) async throws -> DeviceTokenResponseDto
}

final class NotificationRepositoryImpl: NotificationRepository {
    let httpClient = JSONRPCHTTPClient()

    private var baseURL: String {
        GlobalAppState.shared.pushServiceEndpoint
    }

    private var header: [String: String] {
        [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "CHANNEL_ID": "P2PWALLET_MOBILE",
        ]
    }

    func sendDeviceToken(model: DeviceTokenDto) async throws -> DeviceTokenResponseDto {
        do {
            return try await httpClient.request(
                baseURL: baseURL,
                header: header,
                body: .init(
                    method: "add_device",
                    params: [model]
                )
            )
        } catch let error as JSONRPCError<EmptyData> {
            if error.code == -32001 {
                // Already sent
                return .init(
                    deviceToken: model.deviceToken,
                    timestamp: String(Date().timeIntervalSince1970),
                    clientId: model.clientId
                )
            }
            throw error
        } catch {
            throw error
        }
    }

    func removeDeviceToken(model: DeleteDeviceTokenDto) async throws -> DeviceTokenResponseDto {
        try await httpClient.request(
            baseURL: baseURL,
            header: header,
            body: .init(
                method: "delete_device",
                params: [model]
            )
        )
    }
}
