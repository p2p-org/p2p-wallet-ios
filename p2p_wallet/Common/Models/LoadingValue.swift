import Foundation

enum LoadingValue<T> {
    case loading
    case loaded(T)
    case error(Error)
    
    var value: T? {
        switch self {
        case .loaded(let value):
            return value
        default:
            return nil
        }
    }
}
