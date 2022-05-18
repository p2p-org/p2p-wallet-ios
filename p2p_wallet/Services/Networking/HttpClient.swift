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

        do {
            let (data, response) = try await URLSession.shared.data(from: request)
            guard let response = response as? HTTPURLResponse else { throw ErrorModel.noResponse }
            switch response.statusCode {
            case 200 ... 299:
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                guard let decodedResponse = try? decoder.decode(responseModel, from: data) else {
                    throw ErrorModel.decode
                }
                return decodedResponse
            case 401:
                throw ErrorModel.unauthorized
            default:
                throw ErrorModel.unexpectedStatusCode
            }
        } catch {
            throw ErrorModel.unknown
        }
    }
}
