import Foundation

public enum JSBError: Error {
    case invalidContext
    case invalidArgument(String)
    case jsError(Any)
    case floatingNumericIsNotSupport
    case pageIsNotReady
}
