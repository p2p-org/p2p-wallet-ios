import Foundation
import KeyAppNetworking
import XCTest

class HTTPClientTests: XCTestCase {
    
    func testRequest_SuccessfulResponse_ReturnsDecodedModel() async throws {
        // Arrange
        let mockString = """
        {
            "id": 1,
            "name": "John Doe"
        }
        """
        let mockURLSession = MockURLSession(responseString: mockString, statusCode: 200, error: nil)
        let mockDecoder = JSONResponseDecoder()
        
        let httpClient = HTTPClient(urlSession: mockURLSession, decoder: mockDecoder)
        let endpoint = DefaultHTTPEndpoint(baseURL: "https://example.com/api", path: "/users", method: .get, header: [:], body: nil)
        
        // Act
        let userModel: UserModel = try await httpClient.request(endpoint: endpoint, responseModel: UserModel.self)
        
        // Assert
        XCTAssertEqual(userModel.id, 1)
        XCTAssertEqual(userModel.name, "John Doe")
    }
    
    func testRequest_InvalidResponse_ThrowsError() async throws {
        // Arrange
        let mockData = Data()
        let mockURLSession = MockURLSession(responseString: nil, statusCode: 200, error: nil)
        let mockDecoder = JSONResponseDecoder()
        
        let httpClient = HTTPClient(urlSession: mockURLSession, decoder: mockDecoder)
        let endpoint = DefaultHTTPEndpoint(baseURL: "https://example.com/api", path: "/users", method: .get, header: [:], body: nil)
        
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
}
