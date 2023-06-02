import Foundation
import KeyAppNetworking
import XCTest

class HTTPClientTests: XCTestCase {
    
//    func testRequest_DictionaryBody_ReturnsValidBodyData() async throws {
//        let endpoint =
//    }
    
    func testRequest_SuccessfulResponse_ReturnsDecodedModel() async throws {
        // Arrange
        let mockData = """
        {
            "id": 1,
            "name": "John Doe"
        }
        """.data(using: .utf8)!
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com/api")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let mockURLSession = MockURLSession(data: mockData, response: mockResponse, error: nil)
        let mockDecoder = MockDecoder()
        
        let httpClient = HTTPClient(urlSession: mockURLSession, decoder: mockDecoder)
        let endpoint = DefaultHTTPEndpoint(baseURL: "https://example.com/api", path: "/users", method: .get, header: [:])
        
        // Act
        let userModel: UserModel = try await httpClient.request(endpoint: endpoint, responseModel: UserModel.self)
        
        // Assert
        XCTAssertEqual(userModel.id, 1)
        XCTAssertEqual(userModel.name, "John Doe")
    }
    
    func testRequest_InvalidURL_ThrowsError() async throws {
        // Arrange
        let mockURLSession = MockURLSession(data: nil, response: nil, error: nil)
        let mockDecoder = MockDecoder()
        
        let httpClient = HTTPClient(urlSession: mockURLSession, decoder: mockDecoder)
        let endpoint = DefaultHTTPEndpoint(baseURL: "https://www.ap le.com", path: "/users", method: .get, header: [:])
        
        // Act & Assert
        do {
            _ = try await httpClient.request(endpoint: endpoint, responseModel: UserModel.self)
            XCTFail()
        } catch let HTTPClientError.invalidURL(url) {
            XCTAssertEqual(url, "https://www.ap le.com/users")
        } catch {
            XCTFail()
        }
    }
    
    func testRequest_InvalidResponse_ThrowsError() async throws {
        // Arrange
        let mockData = Data()
        let mockResponse = URLResponse()
        let mockURLSession = MockURLSession(data: mockData, response: mockResponse, error: nil)
        let mockDecoder = MockDecoder()
        
        let httpClient = HTTPClient(urlSession: mockURLSession, decoder: mockDecoder)
        let endpoint = DefaultHTTPEndpoint(baseURL: "https://example.com/api", path: "/users", method: .get, header: [:])
        
        // Act & Assert
        do {
            _ = try await httpClient.request(endpoint: endpoint, responseModel: UserModel.self)
            XCTFail()
        } catch let HTTPClientError.invalidResponse(response, data) {
            XCTAssertEqual(response, nil)
            XCTAssertEqual(data, mockData)
        } catch {
            XCTFail()
        }
    }
    
    // MARK: - Helper Classes and Structs
    
    struct UserModel: Codable {
        let id: Int
        let name: String
    }
    
    class MockURLSession: HTTPURLSession {
        private let mockData: Data?
        private let mockResponse: URLResponse?
        private let mockError: Error?
        
        init(data: Data?, response: URLResponse?, error: Error?) {
            self.mockData = data
            self.mockResponse = response
            self.mockError = error
        }
        
        func data(from request: URLRequest) async throws -> (Data, URLResponse) {
            if let error = mockError {
                throw error
            }
            guard let data = mockData, let response = mockResponse else {
                throw URLError(.badServerResponse)
            }
            return (data, response)
        }
    }
    
    class MockDecoder: HTTPResponseDecoder {
        func decode<T: Decodable>(_ type: T.Type, data: Data, httpURLResponse: HTTPURLResponse) throws -> T {
            return try JSONDecoder().decode(type, from: data)
        }
    }
    
    struct MockEndpoint: HTTPEndpoint {
        struct CustomBody: Encodable {
            let query: String
            let sort: Bool
        }
        
        let baseURL: String
        let path: String
        let method: HTTPMethod
        let header: [String : String]
        let body: CustomBody?
    }
}

