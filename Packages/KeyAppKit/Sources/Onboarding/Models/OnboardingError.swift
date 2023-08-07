import Foundation

enum OnboardingError: Error {
    case invalidValue(at: String)
    case encodingError(String)
    case decodingError(String)
}
