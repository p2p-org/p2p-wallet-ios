import KeyAppNetworking
import XCTest

final class JSONRPCHTTPClientTests: XCTestCase {
    func testRequest_SuccessfulResponse_ReturnsDecodedModel() async throws {
        // Test request https://www.jsonrpc.org/specification
        let mockParams = JSONRPCRequestDto(
            id: "1",
            method: "subtract",
            params: [42, 23]
        )

        let mockString = #"{"jsonrpc": "2.0", "result": 19, "id": "1"}"#

        let httpClient = JSONRPCHTTPClient(
            urlSession: MockURLSession(
                responseString: mockString,
                statusCode: 200,
                error: nil
            )
        )

        // Act
        let response = try await httpClient.request(
            baseURL: "https://example.com/api",
            path: "/users",
            body: mockParams,
            responseModel: Int.self
        )
        // Assert
        XCTAssertEqual(response, 19)
    }

    func testRequest_UnsuccessfulResponse_ThrowsErrorWithEmptyErrorData() async throws {
        // Test when the server returns a non-successful status code
        let mockParams = JSONRPCRequestDto(
            id: "1",
            method: "subtract",
            params: [42, 23]
        )

        let mockString = #"{"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params"},"id":"1"}"#

        let httpClient = JSONRPCHTTPClient(
            urlSession: MockURLSession(
                responseString: mockString,
                statusCode: 400, // Simulate a bad request
                error: nil
            )
        )

        // Act & Assert
        do {
            _ = try await httpClient.request(
                baseURL: "https://example.com/api",
                path: "/users",
                body: mockParams,
                responseModel: Int.self
            )
            XCTFail()
        } catch let error as JSONRPCError<EmptyData> {
            XCTAssertEqual(error.code, -32602)
            XCTAssertEqual(error.message, "Invalid params")
        } catch {
            XCTFail()
        }
    }

    func testRequest_UnsuccessfulResponse_ThrowsErrorWithCustomErrorData_AsString() async throws {
        // Test when the server returns a non-successful status code with custom error data
        let mockParams = JSONRPCRequestDto(
            id: "1",
            method: "subtract",
            params: [42, 23]
        )

        let mockString = """
            {
                "jsonrpc": "2.0",
                "error": {
                    "code": -32602,
                    "message": "Invalid params",
                    "data": "Additional details"
                },
                "id": "1"
            }
        """

        let httpClient = JSONRPCHTTPClient(
            urlSession: MockURLSession(
                responseString: mockString,
                statusCode: 400, // Simulate a bad request
                error: nil
            )
        )

        // Act & Assert
        do {
            _ = try await httpClient.request(
                baseURL: "https://example.com/api",
                path: "/users",
                body: mockParams,
                responseModel: Int.self
            )
            XCTFail()
        } catch let error as JSONRPCError<String> {
            XCTAssertEqual(error.code, -32602)
            XCTAssertEqual(error.message, "Invalid params")
            XCTAssertEqual(error.data, "Additional details")
        } catch {
            XCTFail()
        }
    }

    func testRequest_UnsuccessfulResponse_ThrowsErrorWithCustomErrorData_AsCustomType() async throws {
        struct User: Decodable {
            let userId: String
            let name: String
        }

        // Test when the server returns a non-successful status code with custom error data
        let mockParams = JSONRPCRequestDto(
            id: "1",
            method: "subtract",
            params: [42, 23]
        )

        let mockString = """
            {
                "jsonrpc": "2.0",
                "error": {
                    "code": -32602,
                    "message": "Invalid user",
                    "data": {"userId":"id","name":"ABC"}
                },
                "id": "1"
            }
        """

        let httpClient = JSONRPCHTTPClient(
            urlSession: MockURLSession(
                responseString: mockString,
                statusCode: 400, // Simulate a bad request
                error: nil
            )
        )

        // Act & Assert
        do {
            _ = try await httpClient.request(
                baseURL: "https://example.com/api",
                path: "/users",
                body: mockParams,
                responseModel: Int.self,
                errorDataType: User.self
            )
            XCTFail()
        } catch let error as JSONRPCError<User> {
            XCTAssertEqual(error.code, -32602)
            XCTAssertEqual(error.message, "Invalid user")
            XCTAssertEqual(error.data?.userId, "id")
            XCTAssertEqual(error.data?.name, "ABC")
        } catch {
            XCTFail()
        }
    }
}
