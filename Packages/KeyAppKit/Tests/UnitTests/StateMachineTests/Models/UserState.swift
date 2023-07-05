import Foundation
import StateMachine

struct UserState: State {
    // MARK: - Properties

    var name: String
    var age: Int

    // MARK: - Computed properties

    var isAdult: Bool {
        age >= 18
    }
    var greeting: String {
        "Hello, my name is \(name) and I'm \(age) years old."
    }
}

