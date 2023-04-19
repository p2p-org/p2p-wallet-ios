import Foundation

public enum PricesAPIError: Error {
    case invalidURL
    case invalidResponseStatusCode(Int?)
}
