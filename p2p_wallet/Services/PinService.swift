import Foundation
import Resolver

enum PincodeServiceError: Error {
    case maxAttemptsReached
}

protocol PincodeService {
    // TODO: Needs to rename it after we change the logic
    // and move it to a service from other palces
    func pincodeSucceed()
    func pincode() -> String?
    func attemptsLeft() -> Int
    func pincodeFailed() throws
    func resetAttempts()
}

class PincodeServiceImpl: PincodeService {
    // MARK: -

    @Injected private var pincodeStorage: PincodeStorageType

    // MARK: -

    private var maxAttempts = 5
    func pincodeFailed() throws {
        // "<" because failed events appears _after_ the attempt
        guard let attempt = pincodeStorage.attempt, attempt + 1 < maxAttempts else {
            throw PincodeServiceError.maxAttemptsReached
        }
        pincodeStorage.saveAttempt(attempt + 1)
    }

    func pincodeSucceed() {
        resetAttempts()
    }

    func pincode() -> String? {
        pincodeStorage.pinCode
    }

    func attemptsLeft() -> Int {
        max(0, maxAttempts - (pincodeStorage.attempt ?? 0))
    }

    func resetAttempts() {
        // It's 1 because we have failure event only _after_ the attempt
        pincodeStorage.saveAttempt(0)
    }
}
