import Combine
import Foundation
import Resolver

class LoginViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected private var loginService: LoginService

    // MARK: - Input

    @Published var username: String = ""
    @Published var password: String = ""

    // MARK: - Output

    var recommendation: AnyPublisher<String?, Never> {
        credential
            .map { name, password -> String? in
                guard !name.isEmpty, !password.isEmpty else {
                    return "Fill name and password"
                }
                if name.count < 8 || password.count < 8 {
                    return "Name or password should be more than 8 characters"
                }
                return nil // all good!
            }
            .eraseToAnyPublisher()
    }

    var isCredenticalsValid: AnyPublisher<Bool, Never> {
        credential
            .map { name, password -> Bool in
                name.count >= 8 && password.count >= 8
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Action

    func login() async throws {
        try await loginService.login(username: username, password: password)
    }

    // MARK: - Helpers

    private var credential: AnyPublisher<(String, String), Never> {
        Publishers.CombineLatest(
            $username,
            $password
        )
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
