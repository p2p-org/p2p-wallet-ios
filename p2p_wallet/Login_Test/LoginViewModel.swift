import AnalyticsManager
import Combine
import Foundation
import Resolver

protocol LoginService {
    func login(username: String, password: String) async throws
}

class LoginViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected private var loginService: LoginService

    // MARK: - Input

    @Published var username: String?
    @Published var password: String?

    // MARK: - Output

    var recommendation: AnyPublisher<String?, Never> {
        credential
            .map { name, password -> String? in
                guard let name = name, let password = password else {
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
                guard let name = name, let password = password else {
                    return false
                }
                return name.count >= 8 && password.count >= 8
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Action

    func login() async throws {
        guard let username = username, let password = password else {
            return
        }

        try await loginService.login(username: username, password: password)
    }

    // MARK: - Helpers

    private var credential: AnyPublisher<(String?, String?), Never> {
        Publishers.CombineLatest(
            $username,
            $password
        )
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
