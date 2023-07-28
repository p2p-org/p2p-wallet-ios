//
//  HttpClient.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//
import Foundation

protocol HttpClient {
    func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async throws -> T
}

final class HttpClientImpl: HttpClient {
    func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async throws -> T {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else { throw ErrorModel.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header

        if let body = endpoint.body {
            request.httpBody = body.data(using: .utf8)
        }

        print(request.cURL())

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw ErrorModel.noResponse }
        switch response.statusCode {
        case 200 ... 299:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let decodedResponse = try? decoder.decode(responseModel, from: data) else {
                if let decodedErrorResponse = try? decoder.decode(JsonRpcResponseErrorDto.self, from: data) {
                    throw decodedErrorResponse.error
                }
                throw ErrorModel.decode
            }
            return decodedResponse
        case 401:
            throw ErrorModel.unauthorized
        default:
            throw ErrorModel.unexpectedStatusCode
        }
    }
}
