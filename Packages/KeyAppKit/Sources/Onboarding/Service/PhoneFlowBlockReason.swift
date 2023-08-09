let blockTime: Double = 60 * 10

public enum PhoneFlowBlockReason: Codable, Equatable {
    case blockEnterPhoneNumber
    case blockResend
    case blockEnterOTP
}
