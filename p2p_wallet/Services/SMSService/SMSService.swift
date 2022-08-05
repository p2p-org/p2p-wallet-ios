import Foundation

enum SMSServiceError: Int, Error, CaseIterable {
    case invalidValue = -32061
    case wait10Min = -32053
    case invalidSignature = -32058
    case parseError = -32700
    case invalidRequest = -32600
    case methodNotFOund = -32601
    case invalidParams = -32602
    case internalError = -32603
    case everytingIsBroken = -32052
    case retry = -32050
    case changePhone = -32054
    case alreadyConfirmed = -32051
    case callNotPermit = -32055
    case pubkeyExists = -32056
    case pubkeyAndPhoneExists = -32057
}

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
    private var code = "000000"
    private var phone: String?

    func sendConfirmationCode(phone: String) async throws {
        debugPrint("SMSServiceImplMock code: \(code) for phone \(phone)")
        sleep(4)

        if let exep = SMSServiceError(rawValue: -(Int(String(phone.suffix(5))) ?? 0)),
           exep.rawValue != SMSServiceError.invalidValue.rawValue
        {
            throw exep
        }

        self.phone = phone
    }

    func confirm(phone: String, code: String) async throws -> Bool {
        sleep(4)
        debugPrint("SMSServiceImplMock confirm isConfirmed: \(code == self.code && phone == self.phone)")

        if let exep = SMSServiceError(rawValue: -(Int(code) ?? 0)),
           exep.rawValue != SMSServiceError.invalidValue.rawValue
        {
            throw exep
        }

        return code == self.code && phone == self.phone
    }

    func isValidCodeFormat(code: String) -> Bool {
        code.count == 6
    }
}
