import Foundation

enum LoadingValue<T> {
    case loading
    case loaded(T)
    case error(Error)

    var value: T? {
        switch self {
        case let .loaded(value):
            return value
        default:
            return nil
        }
    }
}
