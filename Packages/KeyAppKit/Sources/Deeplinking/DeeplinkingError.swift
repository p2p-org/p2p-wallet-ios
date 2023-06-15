import Foundation

public enum DeeplinkingError: Error, Equatable {
    case unsupportedURL(URL?)
}
