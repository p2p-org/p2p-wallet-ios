import Foundation

public class HTTPJSONRPCCLient {
    public struct EmptyParams: Codable {
        public init() {}
    }

    public let encoder: JSONEncoder
    public let decoder: JSONDecoder

    public var endpoint: String
    public let urlSession: URLSession

    public init(endpoint: String, urlSession: URLSession = URLSession.shared) {
        self.endpoint = endpoint
        self.urlSession = urlSession

        encoder = {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            return encoder
        }()

        decoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            return decoder
        }()
    }

    /// Invoke method
    public func invoke(
        method: String,
        params: some Codable
    ) async throws {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let rpcBody = JSONRPCRequest(
            id: UUID().uuidString,
            method: method,
            params: params
        )

        request.httpBody = try encoder.encode(rpcBody)

        let (data, _) = try await urlSession.data(for: request)
        let jsonResponse = try decoder.decode(JSONRPCResponse<String, String>.self, from: data)

        if let error = jsonResponse.error {
            throw error
        } else {
            return
        }
    }

    /// Call and expect result.
    public func call<Result: Codable, AdditionalError: Codable>(
        method: String,
        params: some Codable,
        additionalError _: AdditionalError.Type = String.self
    ) async throws -> Result {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let rpcBody = JSONRPCRequest(
            id: UUID().uuidString,
            method: method,
            params: params
        )

        request.httpBody = try encoder.encode(rpcBody)

        print(request.cURL())

        let (data, _) = try await urlSession.data(for: request)
        debugPrint(String(data: data, encoding: .utf8) as Any)

        let jsonResponse = try decoder.decode(JSONRPCResponse<Result, AdditionalError>.self, from: data)

        if let error = jsonResponse.error {
            throw error
        } else if let result = jsonResponse.result {
            return result
        } else {
            throw JSONRPCError(code: 0, message: "Missing result", data: "")
        }
    }
}
