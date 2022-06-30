import Foundation

protocol LoginService {
    func login(username: String, password: String) async throws
}

class MockLoginService: LoginService {
    enum Error: Swift.Error {
        case fake
    }

    func login(username _: String, password _: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000)
        if Bool.random() {
            throw Error.fake
        }
    }
}
