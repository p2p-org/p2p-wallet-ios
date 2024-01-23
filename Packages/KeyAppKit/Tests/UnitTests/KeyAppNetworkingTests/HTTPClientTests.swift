import Foundation
import KeyAppNetworking
import XCTest

class HTTPClientTests: XCTestCase {
    func testRequest_SuccessfulResponse_ReturnsData() async throws {
        // Arrange
        let mockString =
            #"{"jsonrpc":"2.0","result":{"context":{"apiVersion":"1.16.23","slot":243351571},"value":{"data":{"parsed":{"info":{"decimals":5,"extensions":[{"extension":"transferFeeConfig","state":{"newerTransferFee":{"epoch":530,"maximumFee":50000000000000,"transferFeeBasisPoints":300},"olderTransferFee":{"epoch":530,"maximumFee":50000000000000,"transferFeeBasisPoints":300},"transferFeeConfigAuthority":null,"withdrawWithheldAuthority":"LPF354oHyPWL7BoMRySPQLwfvUyqPBWpwC4R7atptrD","withheldAmount":7859097201}}],"freezeAuthority":null,"isInitialized":true,"mintAuthority":null,"supply":"49999926084710"},"type":"mint"},"program":"spl-token-2022","space":278},"executable":false,"lamports":127489312769,"owner":"TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb","rentEpoch":0,"space":278}},"id":1}"#
        let mockURLSession = MockURLSession(
            responseString: mockString,
            statusCode: 200,
            error: nil
        )

        let httpClient = HTTPClient(
            urlSession: mockURLSession
        )
        let endpoint = try DefaultHTTPEndpoint(
            baseURL: "https://example.com/api",
            path: "",
            method: .post,
            header: [:],
            body: #"["FLUXBmPhT3Fd1EDVFdg46YREqHBeNypn1h4EbnTzWERX", { "encoding": "jsonParsed" }]"#
        )

        // Act
        let data = try await httpClient.requestData(
            endpoint: endpoint
        )

        // Assert
        XCTAssertEqual(
            data.base64EncodedString(),
            "eyJqc29ucnBjIjoiMi4wIiwicmVzdWx0Ijp7ImNvbnRleHQiOnsiYXBpVmVyc2lvbiI6IjEuMTYuMjMiLCJzbG90IjoyNDMzNTE1NzF9LCJ2YWx1ZSI6eyJkYXRhIjp7InBhcnNlZCI6eyJpbmZvIjp7ImRlY2ltYWxzIjo1LCJleHRlbnNpb25zIjpbeyJleHRlbnNpb24iOiJ0cmFuc2ZlckZlZUNvbmZpZyIsInN0YXRlIjp7Im5ld2VyVHJhbnNmZXJGZWUiOnsiZXBvY2giOjUzMCwibWF4aW11bUZlZSI6NTAwMDAwMDAwMDAwMDAsInRyYW5zZmVyRmVlQmFzaXNQb2ludHMiOjMwMH0sIm9sZGVyVHJhbnNmZXJGZWUiOnsiZXBvY2giOjUzMCwibWF4aW11bUZlZSI6NTAwMDAwMDAwMDAwMDAsInRyYW5zZmVyRmVlQmFzaXNQb2ludHMiOjMwMH0sInRyYW5zZmVyRmVlQ29uZmlnQXV0aG9yaXR5IjpudWxsLCJ3aXRoZHJhd1dpdGhoZWxkQXV0aG9yaXR5IjoiTFBGMzU0b0h5UFdMN0JvTVJ5U1BRTHdmdlV5cVBCV3B3QzRSN2F0cHRyRCIsIndpdGhoZWxkQW1vdW50Ijo3ODU5MDk3MjAxfX1dLCJmcmVlemVBdXRob3JpdHkiOm51bGwsImlzSW5pdGlhbGl6ZWQiOnRydWUsIm1pbnRBdXRob3JpdHkiOm51bGwsInN1cHBseSI6IjQ5OTk5OTI2MDg0NzEwIn0sInR5cGUiOiJtaW50In0sInByb2dyYW0iOiJzcGwtdG9rZW4tMjAyMiIsInNwYWNlIjoyNzh9LCJleGVjdXRhYmxlIjpmYWxzZSwibGFtcG9ydHMiOjEyNzQ4OTMxMjc2OSwib3duZXIiOiJUb2tlbnpRZEJOYkxxUDVWRWhka0FTNkVQRkxDMVBIbkJxQ1hFcFB4dUViIiwicmVudEVwb2NoIjowLCJzcGFjZSI6Mjc4fX0sImlkIjoxfQ=="
        )
//        XCTAssertEqual(userModel.name, "John Doe")
    }

    func testRequest_SuccessfulResponse_ReturnsDecodedModel() async throws {
        // Arrange
        let mockString = """
        {
            "id": 1,
            "name": "John Doe"
        }
        """
        let mockURLSession = MockURLSession(
            responseString: mockString,
            statusCode: 200,
            error: nil
        )
        let mockDecoder = JSONResponseDecoder()

        let httpClient = HTTPClient(
            urlSession: mockURLSession,
            decoder: mockDecoder
        )
        let endpoint = DefaultHTTPEndpoint(
            baseURL: "https://example.com/api",
            path: "/users",
            method: .get,
            header: [:],
            body: nil
        )

        // Act
        let userModel: UserModel = try await httpClient.request(
            endpoint: endpoint,
            responseModel: UserModel.self
        )

        // Assert
        XCTAssertEqual(userModel.id, 1)
        XCTAssertEqual(userModel.name, "John Doe")
    }

    func testRequest_SuccessfulResponse_ReturnsString() async throws {
        // Arrange
        let mockString = "OK"
        let mockURLSession = MockURLSession(
            responseString: mockString,
            statusCode: 200,
            error: nil
        )
        let mockDecoder = JSONResponseDecoder()

        let httpClient = HTTPClient(
            urlSession: mockURLSession,
            decoder: mockDecoder
        )
        let endpoint = DefaultHTTPEndpoint(
            baseURL: "https://example.com/api",
            path: "/users",
            method: .post,
            header: [:],
            body: nil
        )

        // Act
        let response = try await httpClient.request(
            endpoint: endpoint,
            responseModel: String.self
        )

        // Assert
        XCTAssertEqual(response, "OK")
    }

    func testRequest_InvalidResponse_ThrowsError() async throws {
        // Arrange
        let mockData = Data()
        let mockURLSession = MockURLSession(
            responseString: nil,
            statusCode: 200,
            error: nil
        )
        let mockDecoder = JSONResponseDecoder()

        let httpClient = HTTPClient(
            urlSession: mockURLSession,
            decoder: mockDecoder
        )
        let endpoint = DefaultHTTPEndpoint(
            baseURL: "https://example.com/api",
            path: "/users",
            method: .get,
            header: [:],
            body: nil
        )

        // Act & Assert
        do {
            _ = try await httpClient.request(
                endpoint: endpoint,
                responseModel: UserModel.self
            )
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
