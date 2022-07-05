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

    @Published private(set) var recommendation: String? = nil
    @Published private(set) var isCredentialValid: Bool = false

    // MARK: - Initializers

    override init() {
        super.init()

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
            .assign(to: \.recommendation, on: self)
            .store(in: &subscriptions)

        credential
            .map { name, password -> Bool in
                name.count >= 8 && password.count >= 8
            }
            .assign(to: \.isCredentialValid, on: self)
            .store(in: &subscriptions)
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
