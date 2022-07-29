import Foundation

protocol SMSService {
    func sendConfirmationCode(phone: String) async throws
    func confirm(phone: String, code: String) async throws -> Bool
    func isValidCodeFormat(code: String) -> Bool
}

class SMSServiceImpl: SMSService {
    func sendConfirmationCode(phone _: String) async throws {
        fatalError()
    }

    func confirm(phone _: String, code _: String) async throws -> Bool {
        fatalError()
    }

    func isValidCodeFormat(code _: String) -> Bool {
        fatalError()
    }
}

class SMSServiceImplMock: SMSService {
    private var code = "0000"
    private var phone: String?

    func sendConfirmationCode(phone: String) async throws {
        debugPrint("SMSServiceImplMock code: \(code) for phone \(phone)")
        self.phone = phone
    }

    func confirm(phone: String, code: String) async throws -> Bool {
        debugPrint("SMSServiceImplMock confirm isConfirmed: \(code == self.code && phone == self.phone)")
        return code == self.code && phone == self.phone
    }

    func isValidCodeFormat(code: String) -> Bool {
        code.count == 6
    }
}
