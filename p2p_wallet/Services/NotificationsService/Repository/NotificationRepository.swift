//
//  NotificationRepository.swift
//  p2p_wallet
//
//  Created by Ivan on 29.04.2022.
//

import Foundation
import Resolver
import KeyAppNetworking

protocol NotificationRepository {
    typealias DeviceTokenResponse = JsonRpcResponseDto<DeviceTokenResponseDto>

    func sendDeviceToken(model: DeviceTokenDto) async throws -> DeviceTokenResponse
    func removeDeviceToken(model: DeleteDeviceTokenDto) async throws -> DeviceTokenResponse
}

final class NotificationRepositoryImpl: NotificationRepository {
    private let httpClient: HTTPClient
    
    init() {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

        self.httpClient = .init(
            decoder: JSONRPCDecoder(jsonDecoder: jsonDecoder)
        )
    }

    func sendDeviceToken(model: DeviceTokenDto) async throws -> DeviceTokenResponse {
        do {
            return try await httpClient.sendRequest(
                endpoint: NotifierEndpoint.addDevice(dto: .init(
                    method: "add_device",
                    params: [model]
                )),
                responseModel: DeviceTokenResponse.self
            )
        } catch let error as JsonRpcError where error.code == -32001 {
            return .init(
                id: "",
                result: .init(
                    deviceToken: model.deviceToken,
                    timestamp: String(Date().timeIntervalSince1970),
                    clientId: model.clientId
                )
            )
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
