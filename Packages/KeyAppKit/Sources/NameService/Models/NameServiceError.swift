public struct UndefinedNameServiceError: Error {
    let code: Int
    public static let unknown = UndefinedNameServiceError(code: 0)
}

public enum NameServiceError: Int, Error {
    case invalidOption = -32602
    case config = -32603
    case nameExists = -32001
    case invalidName = -32002
    case invalidAuth = -32003
    case json = -32700
    case ownerHasNames = -32004
}

public enum GetNameError: Int, Error {
    case nameNotFound = -32004
}
